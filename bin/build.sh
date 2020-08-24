#!/usr/bin/env bash

# To stop if any command fails.
set -e

# To stop on unset variables.
set -u

# To be always in project root.
cd "${0%/*}/.."

# To build the application.
elm make src/Main.elm --output bin/elm-json-interop.js --optimize
(
  echo "#!/usr/bin/env node"
  cat bin/elm-json-interop.js |
    sed -E "s/(var \\\$author\\\$project\\\$Main\\\$eval = .*)/\1eval(a);/g"
  echo ""
  echo "const stdin = process.stdin.isTTY ? \"\" : require(\"fs\").readFileSync(0, \"utf-8\");"
  echo "this.Elm.Main.init({ flags: { argv: process.argv, stdin: stdin } } );"
) >bin/elm-json-interop
rm bin/elm-json-interop.js
chmod +x bin/elm-json-interop
