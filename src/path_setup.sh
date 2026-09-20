#!/usr/bin/env bash

# usage: source ./path_setup.sh

SUZUKA_LLAMA_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SUZUKA_LLAMA_COMMAND_DIR="$SUZUKA_LLAMA_DIR/.bin"
SUZUKA_LLAMA_CACHE="$SUZUKA_LLAMA_DIR/models"

mkdir -p "$SUZUKA_LLAMA_COMMAND_DIR"
mkdir -p "$SUZUKA_LLAMA_CACHE"

ln -sfn "$SUZUKA_LLAMA_DIR/suzuka-llama.py" "$SUZUKA_LLAMA_COMMAND_DIR/suzuka-llama"

case ":$PATH:" in
    *":$SUZUKA_LLAMA_COMMAND_DIR:"*)
        ;;
    *)
        export PATH="$SUZUKA_LLAMA_COMMAND_DIR:$PATH"
        ;;
esac

echo "suzuka-llama command enabled for this shell."
echo "  Command: $SUZUKA_LLAMA_COMMAND_DIR/suzuka-llama"
echo "  Cache:   $SUZUKA_LLAMA_CACHE"
