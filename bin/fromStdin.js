#!/usr/bin/env node

Promise.resolve()
  .then(readStdin)
  .then(stdin => generate(stdin))
  .then(a => {
    process.stdout.write(a.stdout)
    process.stderr.write(a.stderr)
    process.exit(a.code)
  })
  .catch(a => {
    process.stderr.write(String(a))
    process.exit(1)
  })

/**
 * @returns {Promise<string>}
 */
function readStdin() {
  return new Promise(resolve => {
    let buffer = ""
    if (process.stdin.isTTY) {
      resolve(buffer)
      return
    }
    process.stdin.setEncoding("utf8")
    process.stdin.on("readable", () => {
      let chunk
      while ((chunk = process.stdin.read())) {
        buffer += chunk
      }
    })
    process.stdin.on("end", () => {
      resolve(buffer)
    })
  })
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
