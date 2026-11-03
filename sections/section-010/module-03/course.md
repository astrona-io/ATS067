---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# Recreate, Feature Flags And Traffic Experiments

This module covers the release patterns that sit beside rolling updates, blue-green and canary: the Recreate strategy, which stops the old version before it starts the new one, feature flags, which separate deploying code from turning a feature on, A/B releases, which route users by a rule, and shadow traffic, which sends a copy of real requests to a version nobody depends on yet. You run each one in a playground and see which Kubernetes object does the work and which part Kubernetes does not do.

## Learning Goals

- Configure the Recreate strategy, explain the downtime it causes and name the cases where it is the right choice.
- Release code with a feature flag held in a ConfigMap and explain why an environment variable and a mounted file react differently to a change.
- Explain the difference between a canary release and an A/B release, and why a plain Service cannot route by header or cookie.
- Send a copy of requests to a new version to compare it with the current version, and choose a release strategy from capacity, risk and tolerance for two versions.

## Before You Start

You should know what a Deployment, a ReplicaSet, a ConfigMap and a Service selector are. The hands-on steps use a playground with a kind cluster and `kubectl`.

## Reading Order

1. The Recreate Strategy And Planned Downtime
2. Feature Flags And Dark Launches
3. A/B Releases And What A Service Cannot Route
4. Shadow Traffic And Choosing A Strategy
5. Summary

<!-- astrona:playground -->
