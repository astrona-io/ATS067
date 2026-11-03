# Overview: Blue-Green And Canary With Services (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a blue and a green version of `scout` and a stable and a canary Deployment of `probe`, and then waits. There is no task, no `astrona submit` and no pass or fail. Switch, scale, measure, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | Deployments `scout-blue`, `scout-green` | 2 replicas each. Blue uses `podinfo:6.15.0` and the message `blue`. Green uses `podinfo:6.14.0` and the message `green`. Pods carry `app: scout` and a `track` label |
  | Service `scout` | The active Service. Its selector is `app: scout` and `track: blue` |
  | Service `scout-preview` | The preview Service. Its selector is `app: scout` and `track: green` |
  | Deployment `probe-stable` | 3 replicas, message `stable`, label `track: stable` |
  | Deployment `probe-canary` | 0 replicas, message `canary`, label `track: canary` |
  | Service `probe` | Selects only `app: probe`, so it covers both probe Deployments |
  | Deployment `shuttle` | One `curl` pod for sending requests |

## Count the answers

Paste this once in each terminal. `count_messages` sends the requested number of requests to a Service and counts how often each message appears.

```sh
count_messages() {
  kubectl -n starfleet exec deploy/shuttle -- sh -c "for i in \$(seq 1 $2); do curl -s http://$1:9898/ | grep -o '\"message\": *\"[a-z]*\"'; done | sort | uniq -c"
}
```

Use it like this: `count_messages scout 10` or `count_messages probe 40`.

## Practice tasks

- Compare the answers of `scout` and `scout-preview`. Switch the selector of `scout` to `track: green`, run `count_messages scout 20` and write down when the answers change. Switch back.
- Scale `scout-green` to 0 and switch `scout` to green. Read the EndpointSlice of `scout` and the answers. Decide what a release gate must check before a switch.
- Scale `probe-canary` to 1, 2 and 3 replicas and run `count_messages probe 60` each time. Compare the share you see with the share you calculate from the pod counts.
- Add a `track` label to a selector of `probe` so that it covers only `stable`. Check that the canary no longer receives requests although its pods are ready.
- Make the canary unready on purpose by changing its readiness probe path, scale it up and check that no request reaches it.
