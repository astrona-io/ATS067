# Question

Solve this question on: `terminal`

The namespace `starfleet` runs four workloads. Three of them need work. Do not delete or scale any Deployment.

1. The Deployment `warp` (3 replicas) was updated to the image `ghcr.io/stefanprodan/podinfo:6.15.0` with the message `version-2`, and the rollout never finished. Make the rollout finish with that image and that message. All 3 pods must be ready and updated. From now on the Deployment must use the `RollingUpdate` strategy with `maxSurge` 1 and `maxUnavailable` 0, wait at least 5 seconds of stable readiness (`minReadySeconds`) and report a stalled rollout after at most 180 seconds (`progressDeadlineSeconds`).

2. The Deployment `impulse` (2 replicas) was updated to an image that cannot be pulled. Go back to the last good revision. Its image must be `ghcr.io/stefanprodan/podinfo:6.15.0` again and both pods must be ready.

3. The Service `shield` serves the application from the Deployment `shield-blue`. The Deployment `shield-green` runs the new version and is ready. Switch the Service so that its traffic goes to the green pods only. The blue pods must keep running with 2 ready replicas.

4. Record the result in a ConfigMap `release-record` in `starfleet` with these keys:
   - `warp-revision`: the revision number of the Deployment `warp` after your fix.
   - `impulse-revision`: the revision number of the Deployment `impulse` after the rollback.
   - `shield-track`: the track that the Service `shield` serves now.
   - `observed-at`: the time of your last check in UTC, in the form `2026-11-03T10:15:00Z`.

`kubectl` already points at the cluster as the cluster administrator. The revision number is in the annotation `deployment.kubernetes.io/revision` of the Deployment. The pods carry the label `track` where a track exists.

Check your work with `astrona submit`.
