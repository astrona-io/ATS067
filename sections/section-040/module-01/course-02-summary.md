---
draft: true
exam_objectives:
- Architecture Patterns (in-cluster and external reconciler, state store management,
  etc.)
---
# Summary

GitOps architecture connects state stores, renderers, agents and target environments through defined trust boundaries. In-cluster and external agents have different credential and failure-domain tradeoffs. Repository layouts can separate application source, environment intent and shared bases, but no layout automatically provides safe ownership. Bootstrap and recovery remain explicit responsibilities. The architecture should make it clear which version and agent govern each target.
