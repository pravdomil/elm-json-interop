#!/usr/bin/env node

const { realpathSync, readFileSync, writeFileSync, mkdirSync } = require("fs")
const { dirname, basename } = require("path")

const usage = "Usage: elm-json-interop [file.elm ...]"

const main = async a => (a.length === 0 ? usage : (await Promise.all(a.map(file))).join("\n"))

const file = async p => {
  const path = realpathSync(p)

  const content = readFileSync(path, { encoding: "utf8" })
  const { stdout } = await convert(content)
  const [encode, decode, ts] = JSON.parse(stdout)

  const pathBasename = basename(path, ".elm")
  const newFolder = dirname(path) + "/" + pathBasename
  mkdirSync(newFolder, { recursive: true })
  writeFileSync(newFolder + "/Encode.elm", encode)
  writeFileSync(newFolder + "/Decode.elm", decode)
  writeFileSync(newFolder + "/" + pathBasename + ".ts", ts)

  return "I have generated JSON encoders/decoders and TypeScript definitions in folder:\n" + newFolder
}

const convert = a => {
  return new Promise(resolve => {
    require("../dist/main.js")
      .Elm.Main.init({ flags: { argv: [], stdin: a } })
      .ports.exit.subscribe(resolve)
  })
}

main(process.argv.slice(2)).then(a => console.log(a)).catch(a => console.error(a))
