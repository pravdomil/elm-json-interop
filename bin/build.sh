set -e
cd "${0%/*}"
cd ..

elm make src/Main.elm --output dist/main.js --optimize
