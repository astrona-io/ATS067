# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- The start downloads manifests of the tools it installs, so the machine needs internet access.

The lab starts a single-node kind cluster (Kubernetes 1.35).
