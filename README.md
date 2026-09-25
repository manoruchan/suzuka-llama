# suzuka-llama

A small, intentionally boring **GGUF manager for llama.cpp**.

`suzuka-llama` downloads GGUF models from Hugging Face, keeps them in a local cache, and helps you inspect and resolve their paths.

It is intended for trying models quickly before building a more complete llama.cpp-based system. It does not replace llama.cpp or try to become an independent inference platform.

## Requirements

* Linux
* Bash
* Python 3
* [Hugging Face](https://huggingface.co/)
* llama.cpp `0.3.0`

The CLI interface of llama.cpp is subject to change. `suzuka-llama` currently targets the llama.cpp `0.3.0` interface.

## Compatibility

Tested only against `llama.cpp@0.3.0` built with Spack.

Other install methods or versions are not guaranteed to work — the llama.cpp CLI interface changes between versions.

## Installation

Clone the repository:

```bash
git clone https://github.com/manoruchan/suzuka-llama.git
cd suzuka-llama
```

Run the setup script:

```bash
bash src/setup_suzuka_llama.sh
source ~/.bashrc
```

This creates the command launcher and the default model cache:

```text
suzuka-llama/
├── .bin/
│   └── suzuka-llama
├── models/
└── suzuka-llama.py
```

The generated files are ignored by Git.

## Cache

By default, models are stored in:

```text
<repository>/models/
```

For example:

```text
/home/suzuka/suzuka-llama/models/
```

`suzuka-llama` sets `LLAMA_CACHE` **only for the `llama-cli` child process used by `pull`**. It does not modify the caller's environment or configure `$LLAMA_CACHE` globally.

An existing Hugging Face cache can be used explicitly with `--cache`:

```bash
suzuka-llama --cache /home/suzuka/.cache/huggingface/hub list
```

This keeps `suzuka-llama` from interfering with an existing llama.cpp or Hugging Face setup.

## Commands

```text
suzuka-llama list
suzuka-llama list --detail

suzuka-llama info <user>/<model>
suzuka-llama files <user>/<model>
suzuka-llama path <user>/<model>
suzuka-llama path <user>/<model> <file>

suzuka-llama pull <user>/<model>[:<quantize>]

suzuka-llama remove <user>/<model>

suzuka-llama load <user>/<model> [file]
suzuka-llama status
suzuka-llama unload
suzuka-llama call "your prompt"
```

## Inspecting the cache

A normal `list` shows one line per repository:

```text
Cache: /home/suzuka/suzuka-llama/models
- ggml-org/Qwen3.5-0.8B-GGUF  (8fea620810c4)
- prism-ml/Ternary-Bonsai-2-27B-gguf  (6ed5e12bf84b)
- unsloth/gemma-4-E4B-it-GGUF  (bfc15c382204)
```

Use `--detail` to inspect the GGUF files inside each snapshot:

```text
Cache: /home/suzuka/suzuka-llama/models

prism-ml/Ternary-Bonsai-2-27B-gguf  (6ed5e12bf84b)
     5.5 GiB  Ternary-Bonsai-2-27B-PTQ1_0.gguf
   600.1 MiB  Ternary-Bonsai-2-27B-mmproj-Q8_0.gguf
```

`files` can also be used to inspect the files in a specific repository:

```bash
suzuka-llama files prism-ml/Ternary-Bonsai-2-27B-gguf
```

Output:

```text
   5.5 GiB  Ternary-Bonsai-2-27B-PTQ1_0.gguf
 600.1 MiB  Ternary-Bonsai-2-27B-mmproj-Q8_0.gguf
```

## Resolving model paths

`path` can print either the repository cache directory or the path to a specific GGUF file.

```bash
suzuka-llama path prism-ml/Ternary-Bonsai-2-27B-gguf
```

Output:

```text
/home/suzuka/suzuka-llama/models/models--prism-ml--Ternary-Bonsai-2-27B-gguf
```

To resolve the actual GGUF file:

```bash
suzuka-llama path prism-ml/Ternary-Bonsai-2-27B-gguf Ternary-Bonsai-2-27B-PTQ1_0.gguf
```

Output:

```text
/home/suzuka/suzuka-llama/models/models--prism-ml--Ternary-Bonsai-2-27B-gguf/snapshots/6ed5e12bf84b7a63069882c91dd9e9218647d17b/Ternary-Bonsai-2-27B-PTQ1_0.gguf
```

The returned path can be passed directly to any llama.cpp build:

```bash
llama-cli -m "$(suzuka-llama path ggml-org/Qwen3.5-0.8B-GGUF Qwen3.5-0.8B-Q4_0.gguf)" -p "こんにちは！"
```

`suzuka-llama` does not need to know which llama.cpp build you use.

For example, a locally built llama.cpp fork can be used directly:

```bash
~/prism-llama.cpp/build/bin/llama-cli -m "$(suzuka-llama path prism-ml/Ternary-Bonsai-2-27B-gguf Ternary-Bonsai-2-27B-PTQ1_0.gguf)" -p "こんにちは！"
```

## Pulling models

Download a GGUF repository from Hugging Face:

```bash
suzuka-llama pull prism-ml/Ternary-Bonsai-2-27B-gguf
```

Or download a specific quantize:

```bash
suzuka-llama pull prism-ml/Ternary-Bonsai-2-27B-gguf:TQ1_0
```

The download is performed through `llama-cli`, with the model cache directed to `suzuka-llama`'s cache.

If multimodal projector files are not needed:

```bash
suzuka-llama pull <user>/<model> --no-mmproj
```

## Removing models

Remove an entire cached repository:

```bash
suzuka-llama remove prism-ml/Ternary-Bonsai-2-27B-gguf
```

**Warning:** `remove` deletes the entire cached repository, including all downloaded GGUF files and other files belonging to that repository. It does not currently support removing an individual file.

This operation cannot be undone by `suzuka-llama`.

## Server workflow

`suzuka-llama` also provides a small optional wrapper around `llama-server`:

```bash
suzuka-llama load unsloth/gemma-4-E4B-it-GGUF gemma-4-E4B-it-Q3_K_M.gguf

suzuka-llama status

suzuka-llama call "Hello!"

suzuka-llama unload
```

The server state is stored outside the repository:

```text
~/.local/state/suzuka-llama/
├── server.json
└── llama-server.log
```

llama-server.log contains the output of the current or most recent llama-server session.
It is replaced when `load` starts a new server.

This workflow is intentionally separate from the core model-management functionality.

## Typical workflow

A simple model-testing workflow is:

```bash
# 1. Find a GGUF on Hugging Face

# 2. Pull it
suzuka-llama pull <user>/<model>:<quantize>

# 3. Inspect the cache
suzuka-llama list --detail

# 4. Resolve the model path
suzuka-llama path <user>/<model> <file>

# 5. Run it with your own llama.cpp build
llama-cli -m "$(suzuka-llama path <user>/<model> <file>)"
```

The same cache can be used with any compatible llama.cpp build, including locally built forks.

## Design

The core idea is deliberately small:

```text
Hugging Face
     │
     ▼
  llama-cli
     │
     ▼
suzuka-llama cache
     │
     ├── list
     ├── files
     ├── path
     ├── info
     └── remove
     │
     ▼
any llama.cpp build
```

`suzuka-llama` manages **models**, not the inference environment.

It provides a convenient bridge between the model ecosystem on Hugging Face and the llama.cpp build you actually want to use.

The project deliberately stays small and predictable.

It is intentionally boring.
