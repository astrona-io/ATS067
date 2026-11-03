# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 5 GiB of free memory.
- `kubectl`, `jq` and `git`.
- The start downloads the manifests of Gitea, Argo CD and Argo Events and their images, so the machine needs internet access.

The lab starts a single-node kind cluster (Kubernetes 1.35).
