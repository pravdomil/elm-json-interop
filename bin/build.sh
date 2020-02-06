#!/usr/bin/env bash

set -e
cd "${0%/*}"
cd ..

elm make src/Main.elm --output dist/main.js --optimize
mv dist/main.js dist/main.cjs
