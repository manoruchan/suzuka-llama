#!/usr/bin/env bash

set -euo pipefail

if [[ "$EUID" -eq 0 ]]; then
    echo "Error: do not run this script with sudo or as root." >&2
    exit 1
fi

LLAMA_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

LLAMA_CACHE="$LLAMA_DIR/models"
BASHRC="$HOME/.bashrc"

mkdir -p "$LLAMA_CACHE"

if ! grep -Fqx '# suzuka-llama' "$BASHRC"; then
    {
        echo
        echo '# suzuka-llama'
        echo "export LLAMA_CACHE=$LLAMA_CACHE"
        echo 'source "$LLAMA_CACHE/../cmd_setup.sh"'
    } >> "$BASHRC"
else
    echo "Warning: existing suzuka-llama configuration found in $BASHRC." >&2
    echo "         Please check LLAMA_CACHE manually if this repository was moved." >&2
fi

echo "Configured llama.cpp:"
echo "  LLAMA_CACHE=$LLAMA_CACHE"
echo

echo "Run:"
echo "  source ~/.bashrc"
