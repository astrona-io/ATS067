---
draft: true
exam_objectives:
- Progressive Delivery Patterns
---
# Summary

Canary delivery increases exposure through supported steps, while blue-green prepares a separate version and changes the active service relationship at promotion. Services and routing integration identify which population receives traffic.

Weights, replica counts and observed requests are different evidence. Capacity, connection persistence and external-state compatibility affect promotion and abort, so an earlier version's availability alone does not establish complete recovery.

AnalysisTemplate defines measurements and decision conditions, while AnalysisRun records an execution with supplied arguments and provider results. Those results influence rollout progression through the configured strategy.

Success must reflect sufficient relevant evidence rather than empty or broken queries. Failure, error and inconclusive behavior need deliberate limits and interpretation, with a response contract that preserves useful diagnosis and external-state recovery.
