---
draft: true
exam_objectives:
  - Pull vs. Event-driven
---
# Pull-Based Reconciliation With Argo CD

This module explains how a pull-based GitOps tool keeps a cluster equal to a Git repository. You will read how an `Application` connects a repository path to a namespace, how the controller compares the two states on a timer and on a change, and what each sync policy does when the states differ. The hands-on steps use a kind cluster with Argo CD and an in-cluster Gitea server as the Git repository.

## Learning Goals

- Explain why a pull-based agent needs no inbound access to the cluster.
- Name the three inputs of an `Application`: the source, the destination and the sync policy.
- Describe the loop of the repository server and the application controller, and the timers that start it.
- Read the sync status (`Synced`, `OutOfSync`) and the health status of an `Application`.
- Tell manual sync from automated sync, and explain `prune` and `selfHeal`.
- Predict what happens to a live change that is not in Git.

## Before You Start

You should know what a Deployment, a namespace and a Git commit are. The hands-on steps use a playground with `kubectl` and `git`. Gitea is plumbing only: it is the Git server and you do not need to learn it.

## Reading Order

1. The Pull Loop: Repository, Desired State And Live State
2. Sync Policies: Manual, Automated, Prune And Self-Heal
3. Summary

<!-- astrona:playground -->
