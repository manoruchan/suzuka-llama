#!/usr/bin/env bash

# usage: source ./path_setup.sh

LLAMA_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
COMMAND_DIR="$LLAMA_DIR/.bin"
LLAMA_CACHE="$LLAMA_DIR/models"

mkdir -p "$COMMAND_DIR"
mkdir -p "$LLAMA_CACHE"

ln -sfn "$LLAMA_DIR/suzuka-llama.py" "$COMMAND_DIR/suzuka-llama"

case ":$PATH:" in
    *":$COMMAND_DIR:"*)
        ;;
    *)
        export PATH="$COMMAND_DIR:$PATH"
        ;;
esac

echo "suzuka-llama command enabled for this shell."
echo "  Command: $COMMAND_DIR/suzuka-llama"
echo "  Cache:   $LLAMA_CACHE"
