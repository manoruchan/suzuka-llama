#!/usr/bin/env bash

# usage: source ./cmd_setup.sh

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_DIR="$SCRIPT_DIR/.bin"

mkdir -p "$COMMAND_DIR"

ln -sfn "$SCRIPT_DIR/suzuka-llama.py" "$COMMAND_DIR/suzuka-llama"

export PATH="$COMMAND_DIR:$PATH"

echo "suzuka-llama command enabled for this shell."
