---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# Blue-Green And Canary With Services

This module explains two release patterns that control who reaches a new version: blue-green, which switches all traffic between two complete versions, and canary, which sends a small share of traffic to the new version first. You build both with Deployments and Services only, so you see which Kubernetes object does the routing and where its limits are.

## Learning Goals

- Build a blue-green release with two Deployments, an active Service and a preview Service, and switch it by changing a selector.
- Explain what a selector switch does to new and to existing connections, and what it cannot undo.
- Build a canary release with replica counts, calculate the traffic share and explain why the observed share can differ.
- Choose evidence to promote or stop a release and compare the capacity and recovery cost of rolling, blue-green and canary releases.

## Before You Start

You should know what a Deployment, a pod label and a Service selector are. The hands-on steps use a playground with a kind cluster and `kubectl`.

## Reading Order

1. Blue-Green Releases With Two Deployments
2. Canary Releases, Traffic Share And Release Evidence
3. Summary

<!-- astrona:playground -->
