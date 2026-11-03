---
draft: true
exam_objectives:
  - Architecture Patterns (in-cluster and external reconciler, state store management, etc.)
---
# Repository Layout And State Store Management

This module explains how to arrange a Git repository so that several environments share manifests without copying them, and how Git works as the store of the desired state. You will read how Kustomize builds an environment from a base and an overlay, how a change is promoted from one environment to the next by a commit, how a bad commit is undone with `git revert`, and what must be stored outside Git. The hands-on steps use a kind cluster with Argo CD and an in-cluster Gitea server.

## Learning Goals

- Describe a Kustomize base and overlay, and render an overlay with `kubectl kustomize`.
- Compare folders per environment, branches per environment and repositories per environment.
- Promote a change from one environment to the next by a commit that touches only the target overlay.
- Undo a faulty commit with `git revert` and explain why history is not rewritten.
- Say what Git stores as desired state, what the cluster stores, and what must not be stored in Git in clear text.
- Explain how a cluster is rebuilt from Git, and what Argo CD keeps in the cluster.

## Before You Start

You should know what an `Application` is, what automated sync does, and how to use `git clone`, `git commit` and `git push`. The hands-on steps use a playground with `kubectl` and `git`. Gitea is plumbing only: it is the Git server and you do not need to learn it.

## Reading Order

1. Kustomize Bases, Overlays And Repository Layout
2. Promotion, Revert And Git As The State Store
3. Summary

<!-- astrona:playground -->
