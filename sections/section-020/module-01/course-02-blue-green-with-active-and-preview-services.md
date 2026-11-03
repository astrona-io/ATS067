---
draft: true
exam_objectives:
  - Progressive Delivery Patterns
---
# Blue-Green With Active And Preview Services

In a blue-green release the new version runs completely next to the old one, and one switch moves the production traffic. Argo Rollouts implements the switch with two Services and a field on the Rollout. This part shows which object changes at each point of the release and what the old version does after the switch.

## The strategy fields

A blue-green Rollout uses `spec.strategy.blueGreen` instead of `canary`:

```yaml
spec:
  replicas: 4
  strategy:
    blueGreen:
      activeService: shield-active
      previewService: shield-preview
      autoPromotionEnabled: false
      previewReplicaCount: 1
      scaleDownDelaySeconds: 30
```

| Field | Default | Meaning |
| --- | --- | --- |
| `activeService` | none, required | The Service that receives production traffic |
| `previewService` | empty | The Service that points to the newest version for tests |
| `autoPromotionEnabled` | `true` | When `false`, the Rollout pauses before the switch |
| `previewReplicaCount` | all replicas | How many pods the new version runs while it is in preview |
| `scaleDownDelaySeconds` | 30 | The time between the switch and the scale-down of the old ReplicaSet |

Both Services must exist before the Rollout. The controller does not create them. They need a selector that matches the pod labels, for example `app: shield`, and the controller adds the hash label to it.

## What the controller changes during a release

Start with the Rollout at version 1. There is one ReplicaSet and both Services select its hash:

```sh
kubectl -n starfleet get service shield-active shield-preview -o custom-columns=NAME:.metadata.name,HASH:.spec.selector.rollouts-pod-template-hash
```

The two Services show the same hash, because the preview Service always follows the newest ReplicaSet and the newest ReplicaSet is the active one.

You change the image. The controller then does these steps:

1. It creates a ReplicaSet for the new template. The status field `status.currentPodHash` becomes the new hash.
2. It scales the new ReplicaSet to `previewReplicaCount` pods, or to all replicas when the field is omitted.
3. It changes the selector of `shield-preview` to the new hash. The preview Service now reaches only the new pods. The selector of `shield-active` keeps the old hash.
4. When `autoPromotionEnabled` is `false`, it adds a pause condition and the phase is `Paused`. When the field is `true`, it continues when the new pods are available.
5. At promotion, it scales the new ReplicaSet to the full replica count, waits until the pods are available, and then changes the selector of `shield-active` to the new hash.
6. After `scaleDownDelaySeconds`, it scales the old ReplicaSet to 0.

Production users see no change until step 5. The switch is the edit of one selector, so the endpoints controller moves the endpoints of `shield-active` from the old pods to the new pods.

## Why the preview is useful and why it is not proof

The preview Service gives a stable address to the new pods. A test job can call `shield-preview` and compare the answer with `shield-active`:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s http://shield-preview:9898/
kubectl -n starfleet exec deploy/shuttle -- curl -s http://shield-active:9898/
```

The `message` field of the answer shows which version replied. The preview test proves that the new pods start, pass readiness and answer simple requests. It does not prove behavior under production traffic, because no production traffic reaches the preview Service. A canary release is the tool for that.

## Capacity during the release

With `previewReplicaCount` omitted, the cluster runs the old and the new version at full size, which doubles the pod count during the release. Setting `previewReplicaCount: 1` limits the cost of the preview stage. At promotion the controller scales the new ReplicaSet to the full count before it switches, so the capacity is needed at that moment anyway. If the nodes cannot schedule the pods, the Rollout stays before the switch and production keeps serving the old version.

## What happens after the switch

The old ReplicaSet stays scaled up for `scaleDownDelaySeconds`. In that time, connections that were opened to the old pods can finish, and a fast rollback is possible. The delay has two purposes:

- Existing connections are not cut by a scale-down.
- Some load balancers and proxies need a few seconds to learn the new endpoints. During that time they can still send requests to the old pods.

After the delay, the old version is gone from the cluster. A later rollback is a new release to the old image: the controller creates a ReplicaSet again, or reuses the retained ReplicaSet, and runs the same stages. Roll back before the delay ends when you can, because the old pods still run.

## Pause and promotion

With `autoPromotionEnabled: false` the Rollout waits in the phase `Paused`. The pause condition has the reason `BlueGreenPause`. Promotion is an action on the Rollout, for example `kubectl argo rollouts promote shield`. A person or an automation that holds the right to update the Rollout status can promote. Treat that right as the release approval, and give it only to the identities that may approve a release.

You can see the paused state without the plugin:

```sh
kubectl -n starfleet get rollout shield -o jsonpath='{.status.phase} {.status.pauseConditions[*].reason}{"\n"}'
kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=shield-preview
kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=shield-active
```

The `Paused` phase is a normal state of this strategy. It is not an error, and the alerting of a team must not treat it as one.

## Analysis before and after the switch

The strategy can run an analysis before the switch (`prePromotionAnalysis`) and after it (`postPromotionAnalysis`). A failed pre-promotion analysis aborts the release before production traffic moves. A failed post-promotion analysis aborts the release and switches the active Service back to the previous ReplicaSet. The post-promotion rollback works only while the old ReplicaSet still exists, so `scaleDownDelaySeconds` must be longer than the analysis.

## Failure cases to recognise

- The preview Service has no endpoints: the new pods are not ready, or the base selector does not match the pod labels.
- The active Service has no endpoints at the start: it points to a hash that no pod carries. The controller switches an active Service that routes to nothing immediately.
- The release is promoted while the new ReplicaSet is not available: the controller waits and does not switch.
- Capacity is short: the new ReplicaSet stays below the replica count and the Rollout does not leave `Progressing`.

## Common pitfalls

> [!WARNING]
> The preview Service shows the new version to testers only. It does not prove behavior under production load. A shorter `scaleDownDelaySeconds` than the time a client needs to learn the new endpoints can cut running requests.
