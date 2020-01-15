#!/usr/bin/env node

Promise.resolve()
  .then(readStdin)
  .then(stdin => run(process.argv, stdin))
  .then(v => exit(v.code, v.stdout, v.stderr))
  .catch(e => exit(1, "", String(e)))

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

function run(argv, stdin) {
  return new Promise(resolve => {
    require("../dist/main.js")
      .Elm.Main.init({ flags: { argv, stdin } })
      .ports.exit.subscribe(resolve)
  })
}

function exit(code, stdout, stderr) {
  process.stdout.write(stdout)
  process.stderr.write(stderr)
  process.exit(code)
}
