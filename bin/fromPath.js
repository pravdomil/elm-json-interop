#!/usr/bin/env node

const { realpathSync, readFileSync, writeFileSync, mkdirSync } = require("fs")
const { dirname, basename } = require("path")

Promise.resolve()
  .then(() => main(process.argv.slice(2)))
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
    return "Usage: elm-json-interop [file.elm ...]"
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
  const { stdout } = await generate(content)
  const [encode, decode, ts] = JSON.parse(stdout)

  const elmBasename = basename(path, ".elm")
  const generatedFolder = dirname(path) + "/" + elmBasename

  mkdirSync(generatedFolder, { recursive: true })
  writeFileSync(generatedFolder + "/Encode.elm", encode)
  writeFileSync(generatedFolder + "/Decode.elm", decode)
  writeFileSync(generatedFolder + "/" + elmBasename + ".ts", ts)

  return "I have generated JSON encoders/decoders and TypeScript definitions in folder:\n" + generatedFolder
}

/**
 * @param {string} stdin
 * @returns {Promise<{code : number, stdout : string, stderr : string}>}
 */
function generate(stdin) {
  return new Promise(resolve => {
    // @ts-ignore
    require("../dist/main.js")
      .Elm.Main.init({ flags: { argv: [], stdin } })
      .ports.exit.subscribe(resolve)
  })
}
