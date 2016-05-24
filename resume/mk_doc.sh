#!/usr/bin/env bash
if [[ $# != 1 ]]; then
    echo "Usage: $0 <jade-file>"
    exit 1
fi
#link='Tim-Keith-resume'
base=$(basename $1 .jade)
jade $base.jade \
    && libreoffice --headless --convert-to odt $base.html \
    && rm $base.html
