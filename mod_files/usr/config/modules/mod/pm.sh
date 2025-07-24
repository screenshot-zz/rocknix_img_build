#!/bin/bash
# make by G.R.H

. /etc/profile

SHDIR=`cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P`

mpv --really-quiet --image-display-duration=6000 "$SHDIR/res/ing.png" &
pid=$(pidof mpv)
tar -xf /storage/data/pm.tar.gz -C /storage/roms
mpv --really-quiet --image-display-duration=6000 "$SHDIR/res/done.png" &
sleep 0.5
$ESUDO kill -9 ${pid} &> /dev/null
pid=$(pidof mpv)
sleep 3
$ESUDO kill -9 ${pid} &> /dev/null

exit 0
