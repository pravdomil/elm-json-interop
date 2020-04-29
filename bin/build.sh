#!/usr/bin/env bash

# To stop if something fails.
set -e

# To be always in project root.
cd "${0%/*}/.."

# To build the application.
elm make src/Main.elm --output dist/main.js --optimize
