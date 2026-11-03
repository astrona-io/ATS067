---
draft: true
exam_objectives:
  - Architecture Patterns (in-cluster and external reconciler, state store management, etc.)
---
# Agent Placement, Credentials And Failure Domains

This module explains where the reconciler of a GitOps tool can run, which credentials each placement needs, and what keeps working when one part fails. You will read how Argo CD runs inside a cluster, how one control plane can manage other clusters, and how an `AppProject` limits which repositories, clusters, namespaces and object kinds an `Application` may use. The hands-on steps use a kind cluster with Argo CD and an in-cluster Gitea server.

## Learning Goals

- Compare a reconciler inside the cluster, one hub that manages many clusters, and one reconciler per cluster.
- Say which credentials each placement needs, and which side opens the connection.
- Name the failure domains of Argo CD and predict what keeps running when one of them stops.
- Write an `AppProject` with `sourceRepos`, `destinations` and a cluster resource allow list.
- Explain how an `Application` is checked against its project and what the error looks like.
- Describe how Argo CD stores repository and cluster credentials as Kubernetes Secrets.

## Before You Start

You should know what an `Application` is, what automated sync does, and how to read `kubectl get -o yaml`. The hands-on steps use a playground with `kubectl` and `git`. Gitea is plumbing only: it is the Git server and you do not need to learn it.

## Reading Order

1. Where The Reconciler Runs: In-Cluster, Hub And Per-Cluster Agents
2. AppProjects, Destinations And Credentials
3. Summary

<!-- astrona:playground -->
