#!/usr/bin/env bash
if [[ $# != 1 ]]; then
    echo "Usage: $0 <jade-file>"
    exit 1
fi
link='Tim-Keith-resume'
base=$(basename $1 .jade)
jade $base.jade \
    && html2text < $base.html > $base.txt \
    && rm $base.html \
    && rm -f $link.txt \
    && ln -s $base.txt $link.txt
echo "Generated $base.txt <- $link.txt"
