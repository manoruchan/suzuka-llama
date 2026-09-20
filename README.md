# suzuka-llama

A small, intentionally boring controller for llama.cpp's Hugging Face cache and `llama-server`.

`suzuka-llama` provides a local CLI for:

* inspecting its project-local llama.cpp Hugging Face cache
* downloading and removing models
* selecting cached GGUF models
* starting and stopping `llama-server`
* calling the loaded model through its OpenAI-compatible API

It does not try to replace llama.cpp. It provides a small interface around `llama-cli` and `llama-server`.

---

## Purpose

`suzuka-llama` is a small CLI for **trying GGUF models before building a more complete llama.cpp-based system**.

Its purpose is to make it easy to:

* find and download GGUF models from Hugging Face
* load a specific quantization
* run a few prompts against the model
* observe inference speed and basic runtime behavior
* compare candidate models on real hardware

The intended workflow is:

```text
Hugging Face → download → load → test → compare → choose a model
```

Once a suitable model has been selected, a more complete application, LLM pipeline, or other system can be built directly on top of `llama.cpp`.

`suzuka-llama` intentionally stops before that point.

It is not an orchestration framework, workflow engine, multi-model platform, distributed inference system, or replacement for `llama.cpp`.

---

## Requirements

* Linux
* Bash
* Python 3
* `llama.cpp` 0.3.0

  * `llama-cli`
  * `llama-server`

The expected `llama.cpp` version is **0.3.0**.

The reference build is `llama.cpp@0.3.0` built with Spack for the Broadwell architecture.

`llama-cli` and `llama-server` must be available in `PATH`.

`llama.cpp` command-line options may change between versions, so other versions are not guaranteed to be compatible.

---

## Installation

Clone the repository:

```bash
git clone <repository-url> suzuka-llama
cd suzuka-llama
```

Generate the controller and configure the repository:

```bash
bash src/setup_suzuka_llama.sh
```

The setup script:

* generates `suzuka-llama.py` from `src/suzuka-llama.src`
* creates the project-local `models/` directory
* creates the project-local `.bin/` directory
* creates the `suzuka-llama` command symlink
* adds a `source` entry to `~/.bashrc`

Then reload the shell:

```bash
source ~/.bashrc
```

The shell setup is intentionally performed through `source`, rather than installing a command system-wide.

No files are installed into `/usr/bin`, `/usr/local/bin`, or another system-wide location.

`suzuka-llama` also does **not** modify the global `LLAMA_CACHE` environment variable.

---

## Repository structure

```text
suzuka-llama/
├── LICENSE
├── README.md
└── src/
    ├── path_setup.sh
    ├── setup_suzuka_llama.sh
    └── suzuka-llama.src
```

The following files are generated locally and are not tracked by Git:

```text
suzuka-llama/
├── .bin/
│   └── suzuka-llama -> ../suzuka-llama.py
├── models/
└── suzuka-llama.py
```

`src/suzuka-llama.src` is the source of truth for the generated Python controller.

To regenerate `suzuka-llama.py` after modifying the source:

```bash
bash src/setup_suzuka_llama.sh
```

### Shell setup

`src/path_setup.sh` is intended to be sourced:

```bash
source src/path_setup.sh
```

It adds the repository's `.bin` directory to the current shell's `PATH`.

It does not modify `LLAMA_CACHE`.

Because it is sourced into the current shell, it intentionally does not use `set -euo pipefail`.

---

## Cache

By default, `suzuka-llama` uses its own project-local cache:

```text
<repository>/models
```

This keeps `suzuka-llama` in a closed environment of models that it manages itself.

`suzuka-llama` does not use the caller's global `LLAMA_CACHE` as its default cache, and it does not modify the caller's `LLAMA_CACHE` environment variable.

When `pull` invokes `llama-cli`, `suzuka-llama` temporarily provides its own cache path to that child process:

```text
suzuka-llama
    │
    └── llama-cli
            └── LLAMA_CACHE=<repository>/models
```

The environment of the `suzuka-llama` process itself is not modified.

The cache follows the Hugging Face cache layout used by llama.cpp.

### Explicit cache override

An existing llama.cpp cache can be used explicitly with `--cache`:

```bash
suzuka-llama --cache /path/to/models list
```

This allows an existing cache to be inspected or operated on without making it part of the default `suzuka-llama` environment.

---

## Commands

```text
suzuka-llama list

suzuka-llama info <user>/<model>

suzuka-llama files <user>/<model>

suzuka-llama path <user>/<model>

suzuka-llama pull <user>/<model>

suzuka-llama pull <user>/<model>/<file>

suzuka-llama remove <user>/<model>

suzuka-llama load <user>/<model>

suzuka-llama load <user>/<model> <file>

suzuka-llama status

suzuka-llama unload

suzuka-llama call "your prompt"
```

There are intentionally no command aliases.

---

## Hugging Face targets

Repository targets use the same path style commonly shown by Hugging Face:

```text
<user>/<model>
```

or:

```text
<user>/<model>/<file>
```

For example:

```bash
suzuka-llama pull ggml-org/gemma-4-E4B-it-GGUF/gemma-4-E4B-it-Q4_0.gguf
```

This corresponds to:

```bash
llama-cli \
    --hf-repo ggml-org/gemma-4-E4B-it-GGUF \
    --hf-file gemma-4-E4B-it-Q4_0.gguf
```

`suzuka-llama` does not implement its own Hugging Face downloader. `llama-cli` remains responsible for downloading the model and populating the cache.

`pull` also supports:

```bash
suzuka-llama pull <target> --no-mmproj
```

to pass `--no-mmproj` to `llama-cli`.

---

## Model management

### List cached repositories

```bash
suzuka-llama list
```

### Inspect a repository

```bash
suzuka-llama info unsloth/gemma-4-E4B-it-GGUF
```

### List files in its current snapshot

```bash
suzuka-llama files unsloth/gemma-4-E4B-it-GGUF
```

### Show its cache path

```bash
suzuka-llama path unsloth/gemma-4-E4B-it-GGUF
```

### Remove a cached repository

```bash
suzuka-llama remove unsloth/gemma-4-E4B-it-GGUF
```

**Warning:** `remove` deletes the entire cached Hugging Face repository, not a single GGUF file.

If the repository contains multiple quantizations, such as:

```text
Q4_0
Q4_K_M
Q8_0
```

all of them are removed together.

Use `remove` only when you want to delete the repository and all of its cached model files.

The command asks for confirmation by default. Use `--yes` or `-y` to skip the confirmation prompt.

---

## Loading a model

Start `llama-server` with a cached model:

```bash
suzuka-llama load \
    unsloth/gemma-4-E4B-it-GGUF \
    gemma-4-E4B-it-Q4_K_M.gguf
```

If a repository contains exactly one GGUF model file, the file argument can be omitted:

```bash
suzuka-llama load unsloth/some-model-GGUF
```

When multiple GGUF files are available, the file must be specified.

`mmproj` files are excluded from automatic model selection.

### Server options

`load` supports:

```text
--host <host>           default: 127.0.0.1
--port <port>           default: 8080
--threads <number>
--reasoning <on|off|auto>
--timeout <seconds>     default: 60
```

For example:

```bash
suzuka-llama load \
    unsloth/gemma-4-E4B-it-GGUF \
    gemma-4-E4B-it-Q4_K_M.gguf \
    --threads 8 \
    --reasoning off
```

The default API address is:

```text
http://127.0.0.1:8080
```

`suzuka-llama` waits for `llama-server`'s `/health` endpoint before considering the model loaded.

Only one `suzuka-llama`-managed model can be loaded at a time.

---

## Server status

Check the current server:

```bash
suzuka-llama status
```

Runtime state is stored outside the repository:

```text
~/.local/state/suzuka-llama/
├── server.json
└── llama-server.log
```

`server.json` stores the information needed to identify the managed server, including its PID, model, API address, command, and log path.

The server log contains both stdout and stderr from `llama-server`.

---

## Unloading

Stop the managed server:

```bash
suzuka-llama unload
```

The server is started in its own process session. `unload` therefore terminates the server's process group.

The default shutdown timeout is 10 seconds:

```bash
suzuka-llama unload --timeout 30
```

If the server does not exit after the timeout, `SIGKILL` is used as a fallback.

---

## Calling the model

Once a model is loaded:

```bash
suzuka-llama call "Explain the difference between TCP and UDP."
```

The command uses:

```text
/v1/chat/completions
```

and streams the generated response.

Reasoning can be selected explicitly:

```bash
suzuka-llama call "your prompt" --reasoning off

suzuka-llama call "your prompt" --reasoning on

suzuka-llama call "your prompt" --reasoning auto
```

The default is `off`.

The default request timeout is 300 seconds:

```bash
suzuka-llama call "your prompt" --timeout 600
```

Usage and timing information returned by the server is printed to `stderr`, while generated text is printed to `stdout`.

Example:

```text
[prompt=42 tokens, completion=128 tokens, total=13.52 s, 9.47 tok/s]
```

`call` never automatically loads a model. Run `load` first.

---

## Typical workflow

```bash
# Download
suzuka-llama pull unsloth/gemma-4-E4B-it-GGUF/gemma-4-E4B-it-Q4_K_M.gguf

# Load
suzuka-llama load \
    unsloth/gemma-4-E4B-it-GGUF \
    gemma-4-E4B-it-Q4_K_M.gguf

# Check
suzuka-llama status

# Run inference
suzuka-llama call "Hello!"

# Stop
suzuka-llama unload
```

---

## Design

`suzuka-llama` intentionally keeps a thin layer around llama.cpp:

```text
                 suzuka-llama
                      │
       ┌──────────────┼──────────────┐
       │              │              │
    cache          llama-cli    llama-server
   management      download       inference
       │              │              │
       └──────────────┴──────────────┘
                      │
                  llama.cpp
```

`llama-cli` remains responsible for downloading Hugging Face models.

`llama-server` remains responsible for model inference and serving the API.

`suzuka-llama` provides the cache discovery, model selection, server lifecycle, and API client around them.

The project intentionally avoids adding another abstraction over the model format or inference engine.

---

## Scope

`suzuka-llama` occupies a deliberately small space between Hugging Face and a full llama.cpp-based application:

```text
Hugging Face
      │
      ▼
   download
      │
      ▼
suzuka-llama
      │
   test / compare
      │
      ▼
 choose a model
      │
      ▼
llama.cpp-based
application / pipeline
```

The goal is to make the early part of this process convenient without turning `suzuka-llama` itself into the final LLM platform.

It is intentionally boring.
