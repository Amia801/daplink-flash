#!/bin/sh
# ST-Link V2 clones often boot into the ST bootloader.
# Run this after plugging in if pyocd does not see DAP103.
set -e
DIR=$(cd "$(dirname "$0")" && pwd)
"$DIR/stlink-tool/stlink-tool"
sleep 1
pyocd list
