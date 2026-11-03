---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# Rollback And Version Compatibility

A rollout has stalled, or it has finished and users report errors. The team wants the previous version back quickly. Kubernetes can restore an earlier pod template in one command, but a pod template is only a part of what a release changes. This part shows exactly what a rollback restores, how to run one and which changes it cannot reverse.

## What a rollback restores

A rollback in Kubernetes means setting the Deployment pod template back to the template of an earlier revision. The Deployment controller keeps one ReplicaSet per revision, up to `spec.revisionHistoryLimit`. A rollback copies the template of the chosen ReplicaSet into the Deployment `spec.template`. The controller then runs an ordinary rolling update, with the same `maxSurge` and `maxUnavailable` limits, from the current template to the restored one.

Two details follow from this. First, a rollback does not rewind time. It creates a new revision number whose template equals an old one, and the old revision number disappears from the history because its ReplicaSet is reused. Second, a rollback only restores fields of the pod template: images, environment variables, probes, resource requests, labels and annotations of the pods. Fields outside the template stay as they are. The replica count, the strategy, `minReadySeconds` and the Service are not restored.

The command is `kubectl rollout undo`. Without options, it goes back one revision. With `--to-revision`, it goes to a named revision. The Deployment controller does the work. The command only edits the Deployment, and it needs the permission to patch Deployments.

## Look at the history before you roll back

Each revision records the template it used. Reading the revisions first avoids rolling back to a revision that is also broken. The Deployment `scout` in the playground has several revisions by now, and some of them are broken.

<!-- astrona:playground:renew -->

List the revisions and then inspect one of them:

```sh
kubectl -n starfleet rollout history deployment/scout
kubectl -n starfleet rollout history deployment/scout --revision=1
```

The second command prints the pod template of revision 1: its image, environment variables and probes. Compare it with the current template, which you can print with `kubectl -n starfleet get deployment scout -o yaml`. The revision that you want is the newest one whose template you know to be good. In a team, the annotation `kubernetes.io/change-cause` helps here, because it labels each revision with the reason for the change. You can set it with `kubectl annotate deployment scout kubernetes.io/change-cause="..."` before or after a change.

## Run the rollback

Roll back to the previous revision and wait for the rollout to finish:

```sh
kubectl -n starfleet rollout undo deployment/scout
kubectl -n starfleet rollout status deployment/scout
```

If the revision before the current one is also broken, `rollout undo` restores a broken template, and the rollout stalls again. Name the good revision instead. The number comes from the history output:

```sh
kubectl -n starfleet rollout undo deployment/scout --to-revision=1
kubectl -n starfleet get deployment scout -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

The image shown is the one from revision 1, and the readiness probe path is the one of revision 1 as well. The Deployment controller scaled the ReplicaSet of revision 1 up and the others down, following the rolling update limits.

Now test the statement that a rollback only restores the template. Scale the Deployment, then roll back, and read the replica count:

```sh
kubectl -n starfleet scale deployment/scout --replicas=2
kubectl -n starfleet rollout undo deployment/scout
kubectl -n starfleet get deployment scout -o jsonpath='{.spec.replicas}{"\n"}'
```

The replica count stays at 2. The scale operation changed `spec.replicas`, which is not part of the template, so it created no revision and the undo did not touch it. The same is true for any change you make to the Service, to a ConfigMap that the pods read or to a Secret.

## What the controller does during the undo

The undo is an ordinary rollout, so the same safety limits apply. With `maxSurge: 1` and `maxUnavailable: 0`, the controller scales the ReplicaSet of the restored revision up by one pod, waits until that pod is available and only then scales the broken ReplicaSet down. If the restored template needs a readiness check to pass, the rollback is also gated by it. A rollback to a template that depends on something that no longer exists, for example a Secret that was deleted, stalls like any other broken rollout.

This also means that a rollback is not instant. Its duration equals the time of a rolling update: pod start time, image pull time and the `minReadySeconds` window, multiplied by the number of steps. For a service that is failing badly, teams sometimes use a faster path. They scale the new version down by hand, or they point the Service selector back to the old pods, which is the blue-green technique. Know the real duration of a rollback before an incident, not during it.

## Why an old image can be unsafe

A rollback brings back old code. That code must work with everything else as it is now. Three kinds of change survive a rollback and can break the old version.

The first kind is data. Suppose version 2 of `scout` adds a column to its database table and writes values that version 1 cannot read. After a rollback, version 1 runs against a table with the new column or with new values. Version 1 may fail on them. A rollback of the pods does not reverse the data change.

The second kind is configuration outside the template. A ConfigMap that version 2 needed was edited in place, and the old pods read the new content at their next start. A rollback restarts the pods from an older template, but they mount the same ConfigMap, now changed.

The third kind is side effects that already happened: messages sent, payments made, records written to another service. No rollout command reverses them. The release plan has to say how to detect and repair them.

## Design releases that can be reversed

Teams reduce the risk with an order of changes called expand and contract. In the expand step, the database change is made first and is compatible with both versions, for example by adding a nullable column that the old version ignores. In the next release, the application starts to use the new column. Only after the old version is gone does a later release remove what nobody uses. Each of the three steps can be rolled back on its own, because each version works with the data the previous step left.

Rollback also needs the old ReplicaSet to exist. `revisionHistoryLimit: 0` removes every old ReplicaSet and with it the ability to undo. The cost of keeping revisions is small, because a ReplicaSet with zero replicas uses only an object in the API. Keep a few revisions, and keep the old container image in the registry as long as a rollback to it may be needed.

Finally, decide who triggers a rollback and on what evidence. A stalled rollout is visible in the Deployment conditions. A rollout that completed and then produced errors is visible only in the error rate and latency of real requests. The Deployment controller does not watch either. A person or a tool that reads those signals has to run the rollback.

You now know that a rollback restores the pod template through the rollout history, that it runs as a normal rolling update and that data, configuration and side effects stay outside it. The next question is how to expose a new version to a limited set of users before any rolling update starts, which is what blue-green and canary releases do.

## Common pitfalls

> [!WARNING]
> `rollout undo` without a revision restores the previous template, which may be broken too. A rollback does not restore the replica count, the strategy or the Service. It cannot undo a database change or a side effect, and `revisionHistoryLimit: 0` removes the ability to roll back.
