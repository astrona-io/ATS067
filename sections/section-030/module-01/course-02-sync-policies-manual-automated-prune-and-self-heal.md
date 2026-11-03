---
draft: true
exam_objectives:
  - Pull vs. Event-driven
---
# Sync Policies: Manual, Automated, Prune And Self-Heal

The loop of the controller always compares. Whether it also applies the difference depends on the sync policy. This part explains each setting, what it does to objects that exist only in the cluster or only in Git, and what a person sees when the settings are wrong.

## Manual sync

An `Application` without `syncPolicy.automated` is synced by hand. The controller compares and reports `OutOfSync`, but it changes nothing. A person starts a sync in the web interface, with the Argo CD command-line tool, or by writing an `operation` into the `Application`:

```yaml
operation:
  sync:
    revision: main
```

The controller runs the operation and then removes the field. The result is in `status.operationState`. Manual sync fits a first rollout, an approval step, or an environment where a person must decide when a change goes live.

## Automated sync

```yaml
syncPolicy:
  automated: {}
```

With `automated`, the controller starts a sync by itself when the application is `OutOfSync` because Git changed. It applies the rendered manifests. An empty `automated` block turns on only this behavior, with two safeguards that are off:

- `prune` is `false`. An object that was removed from Git is not deleted from the cluster.
- `selfHeal` is `false`. A live change is not reverted, because the sync is started only by a change in Git.

Automated sync also does not retry a revision that failed. If a sync of a given commit failed, the controller does not try the same commit again until the commit or the application changes.

## Prune

```yaml
syncPolicy:
  automated:
    prune: true
```

When a file is deleted from Git, the objects it created have no manifest any more. Without `prune` these objects stay in the cluster and the application shows `OutOfSync` with the objects marked as requiring pruning. With `prune: true`, an automated sync deletes them. A manual sync can prune too, when the person selects the prune option.

Argo CD prunes only objects that it tracks as its own. It finds them with the tracking label or annotation that it put on the objects when it created them. An object that a person created by hand in the same namespace is not tracked, so it is not pruned.

Prune is dangerous when a path or a repository is wrong. If a commit removes all files in the folder, a pruning sync would delete everything the application owned. The setting `allowEmpty` (default `false`) blocks a sync that would render no objects, so that an empty folder does not delete everything.

## Self-heal

```yaml
syncPolicy:
  automated:
    selfHeal: true
```

With `selfHeal: true`, the controller also starts a sync when the live state changes and no longer equals Git. If a person runs `kubectl scale` on a Deployment that Git manages, the controller sees the change, finds the application `OutOfSync` and applies the manifest from Git. The replica count returns to the value in Git. There is a short delay before the revert, because a sync that was just finished or failed is not repeated at once.

Self-heal makes Git the only way to change the managed fields. A person who needs a fast change must commit it. This is what gives the audit trail its value: a change that is not in Git does not last.

Self-heal only restores fields that the manifest sets. A field that Git does not set, such as an annotation added by another controller, is not touched. If a controller changes a field that Git sets, for example a mutating webhook or an autoscaler that sets `replicas`, the two fight and the application is `OutOfSync` all the time. The setting `ignoreDifferences` in the `Application` tells the comparison to skip such fields.

## The sync options

`syncPolicy.syncOptions` holds switches for the apply step. Two are common:

- `CreateNamespace=true` creates the destination namespace if it does not exist. Without it, a sync to a missing namespace fails.
- `PruneLast=true` deletes objects only after the new objects are healthy.

## Retry

`syncPolicy.retry` tells the controller to retry a failed sync with a back-off. It has a `limit`, a `backoff` with `duration`, `factor` and `maxDuration`. Without it, a failed sync stays failed until something changes.

## Deleting an application

An `Application` with the finalizer `resources-finalizer.argocd.argoproj.io` deletes its managed objects when the application is deleted. Without the finalizer, deleting the `Application` leaves the objects in the cluster, and they are no longer managed. Know which of the two you have before you delete.

## Reading what happened

| Observation | Cause |
| --- | --- |
| `OutOfSync` stays for a new commit and nothing applies | No `automated` block, or the 3-minute refresh has not run yet |
| An object deleted from Git still exists | `prune` is `false` |
| A manual `kubectl scale` stays in place | `selfHeal` is `false` |
| A manual `kubectl scale` returns to the Git value after a short time | `selfHeal` is `true` |
| The sync fails with a missing namespace | `CreateNamespace=true` is not set |
| The application is `OutOfSync` again right after every sync | Another controller changes a field that Git sets |

## What the live-change revert does not cover

Self-heal reverts a field that the manifest sets. It does not delete an extra object that a person created in the namespace without Argo CD, because the object is not tracked. It also does not restore a deleted object that is not in the manifest, because the manifest has no copy of it.

## Try it

In the playground:

1. Read `spec.syncPolicy` of the `Application` and note which settings are on.
2. Run `kubectl -n starfleet scale deployment scout --replicas=5` and watch `kubectl -n starfleet get deployment scout -w` and the sync status. Note whether the value returns.
3. Patch the `Application` to add `selfHeal: true` with `kubectl patch` and repeat the scale. Note the delay.
4. Delete a file from the repository folder, push the commit, and note what happens to the object with `prune` off and then on.
5. Change `targetRevision` to a branch that does not exist and read the message in `status.conditions`.
