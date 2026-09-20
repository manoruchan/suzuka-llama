#!/usr/bin/env bash

set -euo pipefail

LLAMA_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_FILE="$LLAMA_DIR/suzuka-llama.py"

cp "$LLAMA_DIR/suzuka-llama.src" "$PYTHON_FILE" # overwrites the file if already exists

chmod +x "$PYTHON_FILE"

echo "Generated: $PYTHON_FILE"
