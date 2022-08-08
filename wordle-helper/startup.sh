#!/usr/bin/env bash
set -x -e
npx coffee --bare --watch --compile --output js coffee &
npx watchify js/main.js -o app/main.js -v &
cd ..
python -m http.server 8000
