#!/usr/bin/env bash
if [[ $# != 1 ]]; then
    echo "Usage: $0 <jade-file>"
    exit 1
fi
link='Tim-Keith-resume'
base=$(basename $1 .jade)
jade $base.jade \
    && html2pdf $base.html $base.pdf \
    && rm $base.html \
    && rm -f $link.pdf \
    && ln -s $base.pdf $link.pdf
