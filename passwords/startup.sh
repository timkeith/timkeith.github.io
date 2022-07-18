#!/usr/bin/env bash
set -x -e
#./gen_words.pl js/words.js
npx coffee --bare --watch --compile --output js coffee &
npx watchify js/main.js -o passwords.js -v &
../serve.sh
