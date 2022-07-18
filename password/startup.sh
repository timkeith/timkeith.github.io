#!/usr/bin/env bash
set -x -e
npx coffee --bare --watch --compile --output js coffee &
npx watchify js/main.js -o app/password.js -v &
../serve.sh &
