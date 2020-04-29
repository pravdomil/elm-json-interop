#!/usr/bin/env node

import { generate } from "./js/generate.mjs"
import { readStdin } from "./js/readStdin.mjs"

Promise.resolve()
  .then(readStdin)
  .then(generate)
  .then(a => {
    process.stdout.write(JSON.stringify(a))
    process.exit()
  })
  .catch(a => {
    process.stderr.write(String(a))
    process.exit(1)
  })
