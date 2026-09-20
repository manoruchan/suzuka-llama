#!/usr/bin/env bash

set -euo pipefail

LLAMA_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

PYTHON_FILE="$LLAMA_DIR/suzuka-llama.py"
BASHRC="$HOME/.bashrc"

cp "$LLAMA_DIR/src/suzuka-llama.src" "$PYTHON_FILE" # overwrites the file if already exists
chmod +x "$PYTHON_FILE"

mkdir -p "$LLAMA_DIR/models"
mkdir -p "$LLAMA_DIR/.bin"

ln -sfn "$PYTHON_FILE" "$LLAMA_DIR/.bin/suzuka-llama"

if ! grep -Fqx "# suzuka-llama" "$BASHRC"; then
    {
        echo
        echo "# suzuka-llama"
        echo "source \"$LLAMA_DIR/src/path_setup.sh\""
    } >> "$BASHRC"
else
    echo "Warning: existing suzuka-llama configuration found in $BASHRC." >&2
    echo "         Please check the suzuka-llama source path manually if this repository was moved." >&2
fi

echo "Configured suzuka-llama:"
echo "  Repository: $LLAMA_DIR"
echo "  Cache:      $LLAMA_DIR/models"
echo
echo "Run:"
echo "  source ~/.bashrc"
