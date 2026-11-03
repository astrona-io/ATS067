# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory.
- `kubectl` and `jq`.
- The start downloads the Argo Events manifest and its images, so the machine needs internet access.

The lab starts a single-node kind cluster (Kubernetes 1.35).
