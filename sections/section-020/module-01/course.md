---
draft: true
exam_objectives:
  - Progressive Delivery Patterns
---
# Canary Steps And Blue-Green With Argo Rollouts

This module explains how Argo Rollouts turns a pod template change into a staged release. You will read how the controller creates ReplicaSets, how canary steps become pod counts, and how a blue-green release uses an active and a preview Service. The hands-on steps use a kind cluster with the Argo Rollouts controller installed.

## Learning Goals

- Explain how a Rollout owns ReplicaSets and how the hash label separates versions.
- Read `status.stableRS`, `status.currentPodHash`, `status.currentStepIndex` and the pause conditions of a Rollout.
- Calculate the canary pod counts that a `setWeight` step produces without a traffic router.
- Describe how the stable, canary, active and preview Services get their selectors.
- Run a blue-green release that waits before the switch and read which Service reaches which version.
- Explain what `scaleDownDelaySeconds` protects and why a preview test is not production proof.

## Before You Start

You should know what a Deployment, a ReplicaSet and a Service selector are. The hands-on steps use a playground with `kubectl`. The Argo Rollouts kubectl plugin is not installed, so every check reads the Rollout resource directly.

## Reading Order

1. Canary Steps And Replica Weights
2. Blue-Green With Active And Preview Services
3. Summary

<!-- astrona:playground -->
