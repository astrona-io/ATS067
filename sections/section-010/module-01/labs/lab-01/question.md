# Question

Solve this question on: `terminal`

Two releases in the namespace `starfleet` went wrong. Both Deployments were healthy at revision 1 and were then updated. Repair both without deleting or scaling any Deployment.

1. The Deployment `scout` (3 replicas) was updated to the image `ghcr.io/stefanprodan/podinfo:6.15.0` with the message `version-2`, and the rollout never finished. Make the rollout finish with that image and that message. All 3 pods must be ready and updated.

2. The rollout of `scout` must be safe from now on. The Deployment must use the `RollingUpdate` strategy with `maxSurge` 1 and `maxUnavailable` 0, so that capacity never drops during an update. It must wait at least 5 seconds of stable readiness before it counts a pod as available (`minReadySeconds`), and it must report a stalled rollout after at most 180 seconds (`progressDeadlineSeconds`).

3. The Deployment `probe` (2 replicas) was updated to an image that cannot be pulled. Go back to the last good revision. Its image must be `ghcr.io/stefanprodan/podinfo:6.15.0` again, and both pods must be ready.

4. Record the result in a ConfigMap `release-record` in `starfleet` with these keys:
   - `scout-revision`: the revision number of the Deployment `scout` after your fix.
   - `probe-revision`: the revision number of the Deployment `probe` after the rollback.
   - `observed-at`: the time of your last check in UTC, in the form `2026-11-03T10:15:00Z`.

`kubectl` already points at the cluster as the cluster administrator. The revision number is in the annotation `deployment.kubernetes.io/revision` of the Deployment.

Check your work with `astrona submit`.
