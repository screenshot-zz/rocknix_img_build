#!/bin/bash
# make by G.R.H

. /etc/profile

SHDIR=`cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P`

if [ -z "$1" ]; then
        mpv --really-quiet --image-display-duration=6000 "$SHDIR/res/bios.png" &
        pid=$(pidof mpv)
        for file in vmu*
        do
            find /storage/roms/bios -name "${file}" -type f -exec zip -g "/storage/roms/dc_backup.zip" {} &>/dev/null \;
        done
        tar -xf /storage/data/roms.tar.gz -C /storage/roms
        unzip -oq /storage/roms/dc_backup.zip -d /
        rm -rf /storage/roms/dc_backup.zip
        touch /storage/roms/bios/.done
        mpv --really-quiet --image-display-duration=6000 "$SHDIR/res/done.png" &
        sleep 0.5
        $ESUDO kill -9 ${pid} &> /dev/null
        pid=$(pidof mpv)
        sleep 3
        $ESUDO kill -9 ${pid} &> /dev/null
else
        for file in vmu*
        do
            find /storage/roms/bios -name "${file}" -type f -exec zip -g "/storage/roms/dc_backup.zip" {} &>/dev/null \;
        done
        tar -xf /storage/data/roms.tar.gz -C /storage/roms
        unzip -oq /storage/roms/dc_backup.zip -d /
        rm -rf /storage/roms/dc_backup.zip
        touch /storage/roms/bios/.done
fi
exit 0
