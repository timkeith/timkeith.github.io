#!/usr/bin/env bash
set -x -e
# compile .coffee from coffee to js
coffee --bare --watch --compile --output js coffee &

# combine into bundle.js
watchify js/*.js -o bundle.js --debug
