#!/usr/bin/env node

import { mkdirSync, readFileSync, realpathSync, writeFileSync } from "fs"
import { basename, dirname } from "path"
import { generate } from "./js/generate.js"

Promise.resolve(process.argv.slice(2))
  .then(main)
  .then(a => {
    process.stdout.write(a)
    process.exit()
  })
  .catch(a => {
    process.stderr.write(String(a))
    process.exit(1)
  })

/**
 * @param {string[]} a
 * @returns {Promise<string>}
 */
async function main(a) {
  if (a.length === 0) {
    throw "Usage: elm-json-interop [file.elm ...]"
  }
  const result = await Promise.all(a.map(processFile))
  return result.join("\n")
}

/**
 * @param {string} a
 * @returns {Promise<string>}
 */
async function processFile(a) {
  const path = realpathSync(a)

  const content = readFileSync(path, { encoding: "utf8" })
  const [encode, decode, ts] = await generate(content)

  const elmBasename = basename(path, ".elm")
  const generatedFolder = dirname(path) + "/" + elmBasename

  mkdirSync(generatedFolder, { recursive: true })
  writeFileSync(generatedFolder + "/Encode.elm", encode)
  writeFileSync(generatedFolder + "/Decode.elm", decode)
  writeFileSync(generatedFolder + "/" + elmBasename + ".ts", ts)

  return "I have generated JSON encoders/decoders and TypeScript definitions in folder:\n" + generatedFolder
}
