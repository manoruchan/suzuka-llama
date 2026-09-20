# suzuka-llama

`suzuka-llama` is a small, intentionally boring controller around
llama.cpp's Hugging Face cache and `llama-server`.

It provides a local command-line interface for:

* inspecting the llama.cpp Hugging Face cache
* downloading models from Hugging Face
* removing cached repositories
* selecting a cached GGUF model
* starting and stopping `llama-server`
* checking the currently managed server
* sending prompts through llama-server's OpenAI-compatible API

The controller itself is generated from `suzuka-llama.src`.

The generated `suzuka-llama.py` is intentionally not tracked by Git.

---

## Directory structure

The repository contains:

```text
suzuka-lab/
└── suzuka-llama/
    ├── cmd_setup.sh
    ├── path_setup.sh
    ├── setup_suzuka_llama.sh
    └── suzuka-llama.src
```

After setup, the `suzuka-llama` directory additionally contains generated
runtime files:

```text
suzuka-llama/
├── .bin/
│   └── suzuka-llama -> ../suzuka-llama.py
├── models/
├── suzuka-llama.py
└── suzuka-llama.src
```

The generated controller and model cache are intentionally excluded from
Git:

```gitignore
/suzuka-llama/models/
/suzuka-llama/suzuka-llama.py
```

---

# Setup

There are two setup scripts.

## 1. Configure the environment

Run `path_setup.sh` as a normal user:

```bash
cd ~/suzuka-lab/suzuka-llama
bash path_setup.sh
```

Do not run this script with `sudo` or as root.

The script determines the absolute path of the `suzuka-llama` directory,
creates the project-local model cache, and adds the required environment
configuration to `~/.bashrc`.

The resulting configuration has the following form:

```bash
export LLAMA_CACHE=<repository>/suzuka-llama/models
source "$LLAMA_CACHE/../cmd_setup.sh"
```

After running the setup script, reload the shell:

```bash
source ~/.bashrc
```

`path_setup.sh` does not silently replace an existing configuration. If a
`suzuka-llama` section already exists in `~/.bashrc`, it prints a warning so
that the existing `LLAMA_CACHE` setting can be checked manually.

---

## 2. Generate the controller

Run:

```bash
cd ~/suzuka-lab/suzuka-llama
bash setup_suzuka_llama.sh
```

This copies:

```text
suzuka-llama.src
```

to:

```text
suzuka-llama.py
```

and makes the generated Python file executable.

The generated file is overwritten every time the setup script is run.

Therefore, `suzuka-llama.src` is the source of truth:

```text
suzuka-llama.src
        │
        │ setup_suzuka_llama.sh
        ▼
suzuka-llama.py
```

The generated `suzuka-llama.py` is not committed to Git.

---

# Command setup

`cmd_setup.sh` creates a local command directory:

```text
suzuka-llama/.bin/
```

and creates a symbolic link:

```text
.bin/suzuka-llama -> ../suzuka-llama.py
```

It then prepends this directory to `PATH` for the current shell.

This means that `suzuka-llama` is **not installed system-wide**.

It does not install anything into:

```text
/usr/bin
/usr/local/bin
```

The command can also be enabled manually:

```bash
source ~/suzuka-lab/suzuka-llama/cmd_setup.sh
```

Normally `path_setup.sh` adds this command automatically to `~/.bashrc`.

---

# Cache

The controller uses the `LLAMA_CACHE` environment variable when it is set.

The default cache location, when `LLAMA_CACHE` is not set, is:

```text
~/.cache/llama.cpp/models
```

The project setup intentionally changes this to:

```text
<repository>/suzuka-llama/models
```

For example:

```text
~/suzuka-lab/suzuka-llama/models
```

The cache follows the Hugging Face cache layout used by llama.cpp:

```text
models/
└── models--<user>--<model>/
    ├── blobs/
    ├── refs/
    │   └── main
    └── snapshots/
        └── <revision>/
            ├── *.gguf
            └── ...
```

The controller resolves the current snapshot using `refs/main` when
available. If `refs/main` cannot be used, it falls back to the most recently
modified snapshot directory.

---

# Cache override

The global cache can be overridden for an individual command:

```bash
suzuka-llama --cache /path/to/models list
```

The `--cache` option changes `LLAMA_CACHE` for that invocation.

If omitted, the controller uses:

```text
$LLAMA_CACHE
```

or, when that is not set:

```text
~/.cache/llama.cpp/models
```

---

# Commands

The available commands are:

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

suzuka-llama unload

suzuka-llama call "your prompt"

suzuka-llama status
```

There are intentionally no command aliases.

---

# Hugging Face target format

Commands that accept a Hugging Face target understand two forms:

```text
<user>/<model>
```

and:

```text
<user>/<model>/<file>
```

The first two path components identify the Hugging Face repository.
Everything after those two components is treated as the file path.

For example:

```text
ggml-org/gemma-4-E4B-it-GGUF
```

identifies the repository:

```text
ggml-org/gemma-4-E4B-it-GGUF
```

while:

```text
ggml-org/gemma-4-E4B-it-GGUF/gemma-4-E4B-it-Q4_0.gguf
```

identifies both the repository and the specific file:

```text
Repository:
    ggml-org/gemma-4-E4B-it-GGUF

File:
    gemma-4-E4B-it-Q4_0.gguf
```

Repository names must contain exactly the expected `<user>/<model>` shape
and cannot be absolute paths or contain `..` path components.

---

# `list`

List cached Hugging Face repositories and their GGUF model files:

```bash
suzuka-llama list
```

The command first prints the cache root:

```text
Cache: /path/to/cache
```

For each cached repository it displays:

* repository name
* current snapshot revision, abbreviated to 12 characters
* GGUF model files
* file sizes

For example:

```text
Cache: /home/suzuka/suzuka-lab/suzuka-llama/models

unsloth/gemma-4-E4B-it-GGUF  (fc034cfff751)
       4.2 GiB  gemma-4-E4B-it-Q4_K_M.gguf
       2.8 GiB  gemma-4-E4B-it-Q3_K_S.gguf
```

`mmproj` files are not included in the model-file list.

If no cache directory exists, the command reports:

```text
No cache directory.
```

If the cache exists but contains no recognized repositories:

```text
No cached repositories.
```

---

# `info`

Show detailed information about a cached repository:

```bash
suzuka-llama info <user>/<model>
```

Example:

```bash
suzuka-llama info unsloth/gemma-4-E4B-it-GGUF
```

The command displays:

* repository name
* cache path
* total cache directory size
* current revision
* snapshot path
* files contained in the snapshot

Example:

```text
Repository : unsloth/gemma-4-E4B-it-GGUF
Cache path : /home/suzuka/suzuka-lab/suzuka-llama/models/models--unsloth--gemma-4-E4B-it-GGUF
Size       : 7.8 GiB
Revision   : fc034cfff751157913579611efad8462ac1be606
Snapshot   : /home/.../snapshots/fc034cfff751157913579611efad8462ac1be606
  gemma-4-E4B-it-Q3_K_S.gguf
  gemma-4-E4B-it-Q4_K_M.gguf
  mmproj-BF16.gguf
```

Symbolic links in the snapshot are displayed with their targets.

---

# `files`

List all files in the current snapshot of a cached repository:

```bash
suzuka-llama files <user>/<model>
```

Unlike `list`, this command does not restrict the output to GGUF model
files.

It displays the file size and path relative to the snapshot:

```text
     4.2 GiB  gemma-4-E4B-it-Q4_K_M.gguf
     2.8 GiB  gemma-4-E4B-it-Q3_K_S.gguf
     1.1 GiB  mmproj-BF16.gguf
```

---

# `path`

Print the local cache directory for a repository:

```bash
suzuka-llama path <user>/<model>
```

For example:

```bash
suzuka-llama path unsloth/gemma-4-E4B-it-GGUF
```

The command prints the expected repository cache path.

Unlike `info` and `files`, this command does not require the repository to
already exist.

---

# `pull`

Download a model from Hugging Face:

```bash
suzuka-llama pull <user>/<model>
```

or:

```bash
suzuka-llama pull <user>/<model>/<file>
```

For example:

```bash
suzuka-llama pull \
    ggml-org/gemma-4-E4B-it-GGUF/gemma-4-E4B-it-Q4_0.gguf
```

The controller translates this into a `llama-cli` invocation equivalent to:

```bash
llama-cli \
    --hf-repo ggml-org/gemma-4-E4B-it-GGUF \
    --hf-file gemma-4-E4B-it-Q4_0.gguf
```

`llama-cli` is responsible for the actual download.

The controller starts `llama-cli` and sends:

```text
/exit
```

to its standard input after startup, because `pull` is intended to use
`llama-cli` as a model downloader rather than as an interactive inference
session.

The command prints the command being executed:

```text
+ llama-cli --hf-repo ... --hf-file ...
Note: llama-cli downloads and then exits.
```

---

## `--no-mmproj`

`pull` supports:

```bash
suzuka-llama pull <target> --no-mmproj
```

This adds:

```text
--no-mmproj
```

to the underlying `llama-cli` command.

This can be used when the multimodal projector is not wanted.

---

# `remove`

Remove a cached repository:

```bash
suzuka-llama remove <user>/<model>
```

The command asks for confirmation by default:

```text
Remove cached repository <user>/<model>? [y/N]
```

Use:

```bash
suzuka-llama remove <user>/<model> --yes
```

or:

```bash
suzuka-llama remove <user>/<model> -y
```

to skip the confirmation.

This removes the local cache directory.

It does **not** remove anything from Hugging Face.

---

# `load`

`load` starts `llama-server` using a cached GGUF model.

Basic usage:

```bash
suzuka-llama load <user>/<model>
```

When the repository contains multiple GGUF model files, specify the file:

```bash
suzuka-llama load \
    unsloth/gemma-4-E4B-it-GGUF \
    gemma-4-E4B-it-Q4_K_M.gguf
```

The controller searches the latest snapshot for GGUF files.

`mmproj` files are excluded from automatic model-file selection.

If exactly one GGUF model file is present, it can be selected automatically.

If multiple GGUF model files are present, the file must be specified
explicitly.

If no GGUF model file exists, loading fails.

---

## Server options

`load` supports the following options:

### Host

```bash
--host <host>
```

Default:

```text
127.0.0.1
```

### Port

```bash
--port <port>
```

Default:

```text
8080
```

Therefore the default API address is:

```text
http://127.0.0.1:8080
```

### Threads

```bash
--threads <number>
```

If specified, the value is passed directly to `llama-server`:

```text
--threads <number>
```

If omitted, llama-server's own default behavior is used.

### Reasoning

```bash
--reasoning on
--reasoning off
--reasoning auto
```

The default is:

```text
off
```

The selected value is passed to `llama-server`.

### Startup timeout

```bash
--timeout <seconds>
```

Default:

```text
60
```

After starting `llama-server`, `suzuka-llama` waits for the server's
`/health` endpoint to return HTTP 200.

If the process exits before becoming ready, loading fails.

If the server does not become ready within the timeout, the process is
terminated and loading fails.

---

# Managed server state

Runtime state is stored outside the repository:

```text
~/.local/state/suzuka-llama/
├── server.json
└── llama-server.log
```

`server.json` contains information such as:

```text
PID
repository
model target
model path
host
port
command
log path
```

The server log is:

```text
~/.local/state/suzuka-llama/llama-server.log
```

The log receives both stdout and stderr from `llama-server`.

---

# One managed model at a time

`suzuka-llama` manages only one `llama-server` instance at a time.

If a managed server is already running, attempting to load a different model
fails with a message instructing the user to unload the current model first.

For example:

```text
Another model is already loaded: ...
Run `suzuka-llama unload` first.
```

Loading the same model target again is idempotent:

```text
Already loaded: <target>
API: http://127.0.0.1:8080
```

This restriction applies to servers tracked by `suzuka-llama`.

---

# `status`

Show the currently managed server:

```bash
suzuka-llama status
```

When a managed server is running:

```text
Model  : unsloth/gemma-4-E4B-it-GGUF/gemma-4-E4B-it-Q4_K_M.gguf
Path   : /home/suzuka/suzuka-lab/suzuka-llama/models/...
API    : http://127.0.0.1:8080
PID    : 12528
```

The controller determines whether the server is alive using the PID stored
in `server.json`.

If the stored process is no longer alive, stale state is removed and the
command reports:

```text
No suzuka-llama model is loaded.
```

---

# `unload`

Stop the currently managed `llama-server`:

```bash
suzuka-llama unload
```

The server is started in its own process session. Therefore `unload` sends
signals to the server's process group rather than only to the recorded PID.

The shutdown sequence is:

```text
SIGTERM
   │
   │ wait
   ▼
process exits
```

If the server does not exit within the default 10-second timeout:

```text
SIGKILL
```

is sent to the process group.

The timeout can be changed:

```bash
suzuka-llama unload --timeout 30
```

If the process terminates successfully, the state file is removed.

If no managed server is running, stale state is cleared and:

```text
No suzuka-llama model is loaded.
```

is printed.

---

# `call`

`call` sends a prompt to the currently loaded model:

```bash
suzuka-llama call "Hello!"
```

It communicates with:

```text
/v1/chat/completions
```

using llama-server's OpenAI-compatible API.

The request contains:

```json
{
  "model": "<repository>",
  "messages": [
    {
      "role": "user",
      "content": "<prompt>"
    }
  ],
  "stream": true,
  "stream_options": {
    "include_usage": true
  },
  "reasoning_effort": "off"
}
```

The response is consumed as a Server-Sent Events stream.

Generated text is printed incrementally to standard output.

---

## Reasoning mode

`call` supports:

```bash
suzuka-llama call "your prompt" --reasoning off
```

```bash
suzuka-llama call "your prompt" --reasoning on
```

```bash
suzuka-llama call "your prompt" --reasoning auto
```

The default is:

```text
off
```

The selected value is sent as the API's:

```text
reasoning_effort
```

field.

---

## Call timeout

The default request timeout is:

```text
300 seconds
```

It can be changed with:

```bash
suzuka-llama call "your prompt" --timeout 600
```

---

## Usage and performance information

When returned by the server, `suzuka-llama` extracts:

* prompt token count
* completion token count
* elapsed time
* predicted tokens per second

The diagnostic line is printed to `stderr`, for example:

```text
[prompt=42 tokens, completion=128 tokens, total=13.52 s, 9.47 tok/s]
```

The model response itself is written to standard output.

This separation makes it possible to redirect the generated response without
mixing it with the performance information.

---

## Calling without a loaded model

`call` does not automatically load a model.

If no managed `llama-server` is running:

```text
llama-server is not running. Run `suzuka-llama load <user>/<model>` first.
```

The intended workflow is therefore:

```text
pull
  │
  ▼
cached model
  │
  │ load
  ▼
llama-server
  │
  │ call
  ▼
model response
  │
  │ unload
  ▼
stopped
```

---

# Typical workflow

## First-time setup

```bash
cd ~/suzuka-lab/suzuka-llama

bash path_setup.sh
source ~/.bashrc

bash setup_suzuka_llama.sh
```

Then verify the command:

```bash
suzuka-llama
```

---

## Inspect the cache

```bash
suzuka-llama list
```

Inspect a repository:

```bash
suzuka-llama info unsloth/gemma-4-E4B-it-GGUF
```

List its files:

```bash
suzuka-llama files unsloth/gemma-4-E4B-it-GGUF
```

---

## Download a model

```bash
suzuka-llama pull \
    unsloth/gemma-4-E4B-it-GGUF/gemma-4-E4B-it-Q4_K_M.gguf
```

---

## Load a model

```bash
suzuka-llama load \
    unsloth/gemma-4-E4B-it-GGUF \
    gemma-4-E4B-it-Q4_K_M.gguf
```

Check the server:

```bash
suzuka-llama status
```

---

## Run inference

```bash
suzuka-llama call "Explain the difference between TCP and UDP."
```

With reasoning explicitly enabled:

```bash
suzuka-llama call \
    "Explain the difference between TCP and UDP." \
    --reasoning on
```

---

## Stop the model

```bash
suzuka-llama unload
```

---

# Updating `suzuka-llama`

The Python controller is generated from:

```text
suzuka-llama.src
```

After modifying the source:

```bash
bash setup_suzuka_llama.sh
```

The generated executable is replaced:

```text
suzuka-llama.src
        │
        │ copy
        ▼
suzuka-llama.py
        │
        │ symlink
        ▼
.bin/suzuka-llama
```

No system-wide installation is required.

---

# Moving the repository

The cache path written by `path_setup.sh` is based on the location of the
repository at setup time.

If the repository is moved later, the existing `LLAMA_CACHE` entry in
`~/.bashrc` may still point to the old location.

`path_setup.sh` intentionally detects an existing `suzuka-llama`
configuration and warns instead of silently replacing it.

After moving the repository, inspect the following section of `~/.bashrc`:

```bash
# suzuka-llama
export LLAMA_CACHE=<old-path>/suzuka-llama/models
source "$LLAMA_CACHE/../cmd_setup.sh"
```

Update it to point to the new repository location.

---

# Design

`suzuka-llama` deliberately keeps the controller small.

It does not attempt to replace llama.cpp's own model downloading,
model-format handling, or server implementation.

Instead, the responsibilities are divided as follows:

```text
suzuka-llama
    │
    ├── cache inspection
    ├── cache removal
    ├── model selection
    ├── llama-cli orchestration
    ├── llama-server lifecycle
    └── OpenAI-compatible API client
            │
            ▼
        llama.cpp
```

`llama-cli` remains responsible for downloading Hugging Face models.

`llama-server` remains responsible for model inference and serving the API.

`suzuka-llama` provides the small amount of state and lifecycle management
needed to use those components together from a single command.

The intended interface is therefore deliberately simple:

```text
list
info
files
path
pull
remove
load
unload
status
call
```
