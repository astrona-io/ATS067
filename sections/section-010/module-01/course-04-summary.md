---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# Summary

A Deployment replaces pods through ReplicaSets. A change to the pod template creates a new ReplicaSet, and the controller moves replicas from the old ReplicaSet to the new one in steps. The fields `maxSurge` and `maxUnavailable` limit how many extra pods may exist and how many pods may be missing during the steps. Percentages round up for the surge and down for the unavailable limit. Both overlap and capacity follow from these two numbers.

Probes decide when a new pod counts as good. The readiness probe controls whether a pod receives Service traffic and whether it is available for the rollout. The liveness probe restarts a container that has stopped working, and the startup probe holds back the other two probes while the application starts. The field `minReadySeconds` adds a stability window before a ready pod counts as available. The field `progressDeadlineSeconds` makes the controller report `ProgressDeadlineExceeded` when no progress happens, and it does not roll back.

A rollback restores the pod template of an earlier revision by running a new rolling update. It does not restore the replica count, the strategy, other objects or the data. An older image can therefore be unsafe after a data or configuration change. Releases that are changed in compatible steps, with revision history kept, are the ones that can be reversed.

Key facts:

- The Deployment controller creates one ReplicaSet for each pod template.
- Only the pod template starts a rollout and creates a revision.
- A pod can be `Running` and still not ready.
- A stalled rollout keeps the old pods serving when `maxUnavailable` is 0.
- `kubectl rollout undo` needs a known good revision to be useful.

<!-- astrona:playground:destroy -->
