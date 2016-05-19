#!/usr/bin/env bash
set -x -e
# compile .coffee from coffee to js
coffee --bare --watch --compile --output js coffee &

# combine into barn.js
watchify js/*.js -o barn.js --debug
