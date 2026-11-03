# Overview: Recreate, Feature Flags And Traffic Experiments (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a Recreate Deployment, a feature flag in a ConfigMap and two versions of `scout`, and then waits. There is no task, no `astrona submit` and no pass or fail. Change, measure, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | Deployment `ledger` and Service `ledger` | 2 replicas of `podinfo:6.15.0` with `strategy.type: Recreate` |
  | ConfigMap `scout-flags` | One key, `new-checkout`, set to `off` |
  | Deployment `flagcheck` | Reads the flag as the environment variable `FLAG_ENV` and as the file `/etc/flags/new-checkout` |
  | Deployments `scout-a`, `scout-b` | 2 replicas each, with the messages `a` and `b` and a `track` label |
  | Services `scout`, `scout-a`, `scout-b` | `scout` selects both versions, the other two select one each |
  | Deployment `shuttle` | One `curl` pod for sending requests |

## Count the answers

Paste this once in each terminal. `count_messages` sends the requested number of requests to a Service and counts how often each message appears. The optional third argument adds curl options, for example a header.

```sh
count_messages() {
  kubectl -n starfleet exec deploy/shuttle -- sh -c "for i in \$(seq 1 $2); do curl -s $3 http://$1:9898/ | grep -o '\"message\": *\"[a-z]*\"'; done | sort | uniq -c"
}
```

## Practice tasks

- Change the image of `ledger` and watch the pods with `kubectl -n starfleet get pods -l app=ledger --watch`. Note when the first new pod appears compared with the last old pod.
- Patch `ledger` to `RollingUpdate` and change the image again. Compare the order of the pods with the Recreate run.
- Set `new-checkout` to `on` in the ConfigMap. Read the file and the variable in `flagcheck` every few seconds. Then run `kubectl rollout restart` on `flagcheck` and read both again.
- Send requests with `-H X-Beta-User:true` to `scout` and show that the split between `a` and `b` does not change.
- Scale `scout-b` to 0 and send requests to `scout`. Decide which Service a router would need for each user group.
