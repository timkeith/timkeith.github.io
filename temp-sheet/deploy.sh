#!/usr/bin/env bash
#rm -rf deploy
#mkdir deploy
#cp css/style.css deploy/temperature.css
#cp bundle.js deploy/temperature.js
#sed -e 's#css/style.css#temperature.css#' -e 's#bundle.js#temperature.js#' index.html \
#    > deploy/temperature.html
#scp deploy/* root@tim.tkeith.com:/shared/valleyvistafarm.com/sheets

scp temperature.{html,js,css} root@tim.tkeith.com:/shared/valleyvistafarm.com/sheets
