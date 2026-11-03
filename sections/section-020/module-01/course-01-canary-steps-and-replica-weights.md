---
draft: true
exam_objectives:
  - Progressive Delivery Patterns
---
# Canary Steps And Replica Weights

A Deployment can only replace pods in one fixed pattern. Argo Rollouts adds a custom resource named `Rollout` that has the same pod template and replica fields as a Deployment, plus a strategy that describes a staged release. This part explains what the Rollout controller creates, how a list of steps becomes pod counts, and what the controller does when the steps run out.

## A Rollout owns ReplicaSets like a Deployment

A Rollout has `spec.replicas`, `spec.selector` and `spec.template`. When you apply it, the Argo Rollouts controller creates a ReplicaSet for the pod template. When you change the template, it creates a second ReplicaSet and moves replicas between the two. The Kubernetes Deployment controller is not involved, so a Rollout and a Deployment never manage the same pods.

Each ReplicaSet carries a label with the key `rollouts-pod-template-hash`. Its value is a hash of the pod template. The controller adds the label to the pods and to the ReplicaSet selector, so the pods of one version never match the ReplicaSet of another version.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: scout
  namespace: starfleet
spec:
  replicas: 4
  selector:
    matchLabels:
      app: scout
  template:
    metadata:
      labels:
        app: scout
    spec:
      containers:
        - name: scout
          image: ghcr.io/stefanprodan/podinfo:6.15.0
  strategy:
    canary:
      steps:
        - setWeight: 25
        - pause: {duration: 20s}
        - setWeight: 50
        - pause: {duration: 20s}
```

The status of a Rollout names the two ReplicaSets that matter. `status.stableRS` is the hash of the version that the controller treats as stable. `status.currentPodHash` is the hash of the version in the template now. When both are equal, the release is complete. While they differ, a release is in progress.

## Steps are a list that the controller walks in order

The field `status.currentStepIndex` is the position in the list of steps. The controller runs the step at that index, and moves to the next one when the step is done. The step types used in this module are:

| Step | What it does |
| --- | --- |
| `setWeight: N` | Sets the target share of the canary to N percent |
| `pause: {duration: 20s}` | Waits for the given time, then continues |
| `pause: {}` | Waits with no time limit until someone promotes the Rollout |

A `pause` with a duration continues by itself. A `pause` without a duration adds a pause condition to `status.pauseConditions`, and the Rollout stays in the phase `Paused` until a person promotes it, for example with the command `kubectl argo rollouts promote scout`. The plugin sends that command as an update of the Rollout status. The plugin is not installed in the playgrounds of this course, so the exercises use timed pauses.

## From a weight to pod counts

Without a traffic router, the controller can only express a weight through pod counts. It picks the whole-number split of stable and canary pods whose canary share is closest to the target. When two splits are equally close, it rounds up the canary pods.

| Replicas | Weight | Canary pods | Stable pods | Real share |
| --- | --- | --- | --- | --- |
| 4 | 25 | 1 | 3 | 25 percent |
| 4 | 50 | 2 | 2 | 50 percent |
| 10 | 41 | 4 | 6 | 40 percent |
| 3 | 50 | 2 | 1 | 67 percent (1.5 is a tie, so it rounds up) |

The Service in front of the pods then spreads connections over all ready pods, so the traffic share follows the pod ratio. The ratio is a good estimate only when the clients open many connections. A client that keeps one connection open for a long time stays on one pod, whichever version it is.

Replica-based weights also depend on capacity. The controller must start the canary pods before it can send traffic to them, so `maxSurge` and `maxUnavailable` of the strategy limit how fast the counts change. The defaults for the canary strategy are 25 percent each.

## Stable and canary Services

A canary Rollout can name two Services:

```yaml
  strategy:
    canary:
      stableService: scout-stable
      canaryService: scout-canary
```

The controller edits the selectors of these two Services. It adds the `rollouts-pod-template-hash` label of the stable ReplicaSet to `scout-stable` and the label of the canary ReplicaSet to `scout-canary`. The first Service then reaches only stable pods, and the second one reaches only canary pods. This gives you a stable address and a canary address for tests, even when no router splits the traffic.

If the base selector of a Service has a label that the pods do not carry, the Service has no endpoints. Read the endpoints of each Service after you create them and do not trust the Rollout status alone.

## What a release looks like in the status

When you change the image, these things happen in order:

1. The controller creates the new ReplicaSet and the hash `status.currentPodHash` changes. `status.currentStepIndex` is 0.
2. The step `setWeight: 25` scales the new ReplicaSet to 1 pod and the old one stays at 3 pods. The Rollout waits until the new pod is ready.
3. The step `pause` with a duration adds a pause condition and the phase is `Paused`. After 20 seconds the condition is removed.
4. The step `setWeight: 50` scales the new ReplicaSet to 2 pods and the old one to 2 pods.
5. After the last step, the controller scales the new ReplicaSet to 4 pods and sets `status.stableRS` to the new hash. The old ReplicaSet is scaled down after a delay.

You can read the facts without a plugin:

```sh
kubectl -n starfleet get rollout scout -o jsonpath='{.status.phase} {.status.currentStepIndex} {.status.stableRS} {.status.currentPodHash}{"\n"}'
kubectl -n starfleet get replicaset -l app=scout -L rollouts-pod-template-hash
```

## Changing the steps during a release

A change of the steps is not a change of the pod template, so it does not start a new release. The controller restarts the step list at index 0 when the steps change during a release. Use this knowledge when you test: edit the steps before you change the image if you want a clean run.

A new pod template while a release is in progress replaces the canary. The controller stops the current canary, creates a ReplicaSet for the newest template, and restarts at step 0. The old canary ReplicaSet is scaled down. The stable ReplicaSet does not change until a release finishes.

## Failure cases to recognise

- The canary pod never gets ready: the Rollout stays in `Progressing`, and after `progressDeadlineSeconds` (default 600) it becomes `Degraded`. The stable pods keep serving.
- `setWeight` is 100 as the first step: all pods change at once. There is no stage to observe.
- A selector that does not match the template labels: the controller rejects the Rollout. Check `status.message`.
- A Service that is not named in the strategy but selects the app label: it reaches stable and canary pods in the same ratio as the pods.

## Common pitfalls

> [!WARNING]
> A weight of 25 means one pod of four, not exactly 25 percent of requests. An indefinite `pause: {}` blocks the release until somebody promotes it, and a Rollout in that state is not broken.
