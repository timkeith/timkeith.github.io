#!/usr/bin/env bash
set -x -e
#./gen_words.pl > js/words.js
when-changed gen_words.pl -c ./gen_words.pl coffee/Words.coffee &
coffee --bare --watch --compile --output js coffee &
watchify js/main.js -o wordbrain.js -v
