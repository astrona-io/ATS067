# Overview: Canary Steps And Blue-Green With Argo Rollouts (Playground)

This is a **playground**, not a lab. It starts a cluster with the Argo Rollouts controller and two Rollouts at version 1, then waits. There is no task, no `astrona submit` and no pass or fail. Change a Rollout, watch the release, break it on purpose, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.
- The Argo Rollouts controller v1.10.0 in the namespace `argo-rollouts`. The kubectl plugin is not installed, so you read the Rollout resource with `kubectl get rollout -o jsonpath`.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | Rollout `scout` | Canary, 4 replicas of `ghcr.io/stefanprodan/podinfo:6.15.0`, steps `setWeight: 25`, pause 20s, `setWeight: 50`, pause 20s |
  | Services `scout-stable`, `scout-canary` | The stable and canary Services of `scout` |
  | Rollout `shield` | Blue-green, 4 replicas, `autoPromotionEnabled: false`, `scaleDownDelaySeconds: 30` |
  | Services `shield-active`, `shield-preview` | The active and preview Services of `shield` |
  | Deployment `shuttle` | One `curl` pod for requests from inside the cluster |

- The pod variable `PODINFO_UI_MESSAGE` is `version-1`. The answer of the application returns it in the field `message`.

## Read the state without the plugin

```sh
kubectl -n starfleet get rollout scout -o jsonpath='{.status.phase} {.status.currentStepIndex} {.status.stableRS} {.status.currentPodHash}{"\n"}'
kubectl -n starfleet get replicaset -l app=scout -L rollouts-pod-template-hash
kubectl -n starfleet get service scout-stable scout-canary -o custom-columns=NAME:.metadata.name,HASH:.spec.selector.rollouts-pod-template-hash
```

## Practice tasks

- Change the image of `scout` to `ghcr.io/stefanprodan/podinfo:6.14.0` with `kubectl patch`. Watch `currentStepIndex` and the replica counts of the two ReplicaSets at each step and compare them with the table in the reading.
- Change the replicas of `scout` to 10 and the first weight to 41. Count the canary pods.
- Send requests from `shuttle` to `scout-canary` and `scout-stable` during a release and list the `message` values.
- Change a step to `pause: {}` and observe that the Rollout stays `Paused`. Change the steps back and read what the controller does.
- Change the image of `shield` and compare the selectors of `shield-active` and `shield-preview` before and after.
- Set `previewReplicaCount: 1` and count the preview pods. Set `autoPromotionEnabled: true` on a paused release and watch the phase.
- Break the readiness path in the template of `scout` and read the phase after `progressDeadlineSeconds`.
