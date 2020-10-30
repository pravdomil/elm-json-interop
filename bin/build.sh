#!/usr/bin/env bash

# To stop if any command fails.
set -e

# To stop on unset variables.
set -u

# To be in project root.
cd "${0%/*}/.."

# To have dependencies from npm ready.
npm i

# To compile our app.
elm make src/Main.elm --output bin/elm-json-interop.js --optimize
(
  echo "#!/usr/bin/env node"
  sed -E "s/(var \\\$author\\\$project\\\$Eval\\\$eval .*)/\1return eval(_v0);/g" bin/elm-json-interop.js
  echo ""
  echo "this.Elm.Main.init();"
) >bin/elm-json-interop
rm bin/elm-json-interop.js
chmod +x bin/elm-json-interop
