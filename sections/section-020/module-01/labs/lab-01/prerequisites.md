# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`.
- The start downloads the Argo Rollouts manifest, so the machine needs internet access.

The lab starts a single-node kind cluster (Kubernetes 1.35).
