#!/usr/bin/env bash
current=$(cd `dirname $0` && pwd)

init_scripts="$current/init.d/*"
for script in $init_scripts; do
    if [ -f $script -a -x $script ]; then
        echo "start init script: ${script}"
        . $script
    fi
done