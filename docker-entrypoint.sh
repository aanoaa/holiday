#!/bin/sh
set -e
SERVER="$1"

SCRIPT="./script/holiday"
if [ "$SERVER" = "morbo" ]; then
    OPTS="-m development -v -l http://*:5000"
else
    SERVER="hypnotoad"
    OPTS="-f"
fi

$SERVER $OPTS $SCRIPT
