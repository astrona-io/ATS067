---
draft: true
exam_objectives:
- Deployment and Release Patterns
---
# Summary

Rolling updates replace replicas gradually and depend on readiness, compatible versions and adequate capacity. Rollback can restore a previous Pod template, but external state may need a separate recovery procedure.

Blue-green switches traffic between prepared versions; canary limits exposure and expands it using evidence. Every strategy needs a functioning traffic mechanism, representative health measurements and predefined decisions for promotion or reversal.
