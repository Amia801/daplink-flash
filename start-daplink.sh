#!/bin/sh
# ST-Link V2 clones often boot into the ST bootloader.
# Run this after plugging in if the host does not see DAP103.
set -e
DIR=$(cd "$(dirname "$0")" && pwd)
TOOL="$DIR/stlink-tool/stlink-tool"

if [ ! -x "$TOOL" ]; then
    echo "stlink-tool not found at:"
    echo "  $TOOL"
    echo "Build it first, then run this script again:"
    echo "  cd \"$DIR/stlink-tool\" && make"
    exit 1
fi

"$TOOL"
sleep 1

if command -v pyocd >/dev/null 2>&1; then
    pyocd list
elif command -v python3 >/dev/null 2>&1; then
    python3 -m pyocd list
else
    python -m pyocd list
fi
