---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# Rolling Updates And Health Gates

This module explains how a Kubernetes Deployment replaces the pods of one version with the pods of the next, and which checks decide that the new pods may serve traffic. You run real rollouts in a playground, make one stall on purpose and roll it back.

## Learning Goals

- Explain how a Deployment, its ReplicaSets and the pod template hash carry out a rolling update.
- Calculate how `maxSurge` and `maxUnavailable` limit the extra and the missing pods during a rollout.
- Describe what the readiness, startup and liveness probes decide, and how `minReadySeconds` and `progressDeadlineSeconds` change a rollout.
- Roll a Deployment back with the rollout history, and name what a rollback does not undo.

## Before You Start

You should know what a pod, a Service and a namespace are. The hands-on steps use a playground with a kind cluster and `kubectl`. Each technical term is defined where it first appears.

## Reading Order

1. How A Rolling Update Replaces Pods
2. Health Gates: Readiness, Startup, Liveness And Deadlines
3. Rollback And Version Compatibility
4. Summary

<!-- astrona:playground -->
