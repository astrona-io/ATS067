---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# Feature Flags And Dark Launches

The release patterns so far move pods: a new ReplicaSet replaces an old one, or a Service switches to other pods. A feature flag moves the decision somewhere else. The new code is deployed to every pod, but a setting decides whether users reach it. This separates two events that teams often treat as one: deploying code and releasing a feature. This part explains how a flag reaches a running container in Kubernetes, why the way it arrives decides how fast a change takes effect, and which risks a flag adds.

## Deploy and release are two events

A deploy puts a version of the code on the servers. A release makes a feature available to users. With a feature flag, the code of the new feature ships inside the deployed version and stays off. The first deploy of such code is called a dark launch, because the feature runs in production but no user sees it.

A dark launch has three benefits. The deploy can be rolled out and checked with the normal readiness gates, without any user effect. The release becomes a configuration change that takes seconds and that anyone with access can reverse. The team can enable the feature for a few users or one environment first.

The flag must live outside the container image. If the flag were part of the image, changing it would need a new image and a new rollout, which is again a deploy.

## A flag in a ConfigMap

A ConfigMap is a Kubernetes object that stores configuration as key-value pairs. A pod can read a ConfigMap in two ways. It can copy a key into an environment variable, or it can mount the ConfigMap as a volume, where each key becomes a file.

The playground has a ConfigMap `scout-flags` with the key `new-checkout` set to `off`. The Deployment `flagcheck` reads that key in both ways: it sets the environment variable `FLAG_ENV` from the key and mounts the ConfigMap at `/etc/flags`. Check the starting state:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet get configmap scout-flags -o jsonpath='{.data}{"\n"}'
kubectl -n starfleet exec deploy/flagcheck -- printenv FLAG_ENV
kubectl -n starfleet exec deploy/flagcheck -- cat /etc/flags/new-checkout
```

Both reads return `off`. The environment variable and the file come from the same key, so they agree at the start.

## Turn the flag on

Save this as `scout-flags.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-flags
  namespace: starfleet
data:
  new-checkout: "on"
```

Apply it:

```sh
kubectl apply -f scout-flags.yaml
```

Then read both values again. Run the file read first and repeat it every few seconds until it changes:

```sh
kubectl -n starfleet exec deploy/flagcheck -- cat /etc/flags/new-checkout
kubectl -n starfleet exec deploy/flagcheck -- printenv FLAG_ENV
```

The file changes to `on` after a delay. The kubelet, the agent on the node that manages the pods, refreshes mounted ConfigMaps on its sync period, so the delay can be up to about a minute. The environment variable never changes in a running container. The container reads its environment once, when it starts, so `FLAG_ENV` stays `off` until the pod is replaced.

## Pick the delivery that matches the need

The two ways give two different release behaviours.

- An environment variable needs a new pod to change. `kubectl rollout restart deployment/flagcheck` makes the Deployment create new pods from the same template with a new annotation, and the rollout uses the normal strategy and readiness gates. The change is controlled and visible in the rollout history, but it is not instant.
- A mounted file changes without a restart, but only if the application re-reads the file. A program that reads the file once at start-up keeps the old value, exactly like an environment variable.
- A subPath mount never updates. When a ConfigMap key is mounted with `subPath`, the kubelet does not refresh that file.

Restart the pods so that the environment variable follows the flag:

```sh
kubectl -n starfleet rollout restart deployment/flagcheck
kubectl -n starfleet rollout status deployment/flagcheck
kubectl -n starfleet exec deploy/flagcheck -- printenv FLAG_ENV
```

The new pods start with `FLAG_ENV` set to `on`. The restart is a rolling update, so old pods stay until new pods are ready.

## Flags in a GitOps repository

In GitOps, the Git repository holds the desired state, so the ConfigMap with the flag belongs there. A change of the flag is a commit, with an author, a time and a review. The reconciler applies the commit, and a revert of the commit turns the flag off again. This gives a flag change the same audit trail as a code change.

The cost is speed. A commit, a review and a sync can take minutes. When a team needs to switch a flag in seconds, during an incident for example, it often uses a flag service that the application asks at run time. Then the state of the flag is not in Git, and the team must decide how to record changes of it. The two approaches differ in what is auditable and what is instant, and the choice should be on purpose.

## Staged exposure with flags

A flag does not have to be only on or off. A flag service can enable a feature for a percentage of users, for users in a list or for one region. This gives a canary release at the level of users and not pods. The share is exact, because the application counts users, not connections. The same user keeps the same experience, because the decision depends on a stable key such as the user identifier.

A flag also adds code paths. Each flag doubles the number of combinations that tests should cover, and an old flag that nobody removes becomes a hidden source of defects. A team should give each flag an owner and a removal date and delete the flag and the old code path when the release is complete.

## Failure cases

Three failures are common. The first is a flag that is on in one environment and off in another because the ConfigMaps drifted apart, so a test in staging proves nothing about production. The second is a restart that applies the flag to only some pods when the rollout stalls, which leaves old and new values side by side. The third is a flag read at start-up on some pods and at run time on others, which produces different answers behind one Service.

You now know how to ship code that stays off, how a flag reaches a container and why the delivery method sets the speed of the change. The open question is how to show a feature to only some users when the routing is done by a Service, which treats every request the same.

## Common pitfalls

> [!WARNING]
> An environment variable taken from a ConfigMap does not change in a running pod, and a file mounted with `subPath` never updates. Changing the ConfigMap alone does not restart the pods. Check the value inside the pod, not only the ConfigMap, before you say that a flag is on.
