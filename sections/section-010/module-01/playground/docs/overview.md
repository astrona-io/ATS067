# Overview: Rolling Updates And Health Gates (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with one healthy Deployment and then waits. There is no task, no `astrona submit` and no pass or fail. Change the Deployment, watch the rollout, break it on purpose, roll it back, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | Deployment `scout` | 4 replicas of `ghcr.io/stefanprodan/podinfo:6.15.0`, `maxSurge: 1`, `maxUnavailable: 0`, a readiness probe on `/readyz` and `progressDeadlineSeconds: 120` |
  | Service `scout` | Selects the pods with the label `app: scout` on port 9898 |
  | Deployment `shuttle` | One `curl` pod that you can use to send requests to `scout` |

- The pod environment variable `PODINFO_UI_MESSAGE` is `version-1`. The application returns it in the field `message` of its JSON answer.

## Send a request from inside the cluster

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s http://scout:9898/
```

The answer is JSON. Read the fields `hostname`, which names the pod that answered, and `message`.

## Practice tasks

- Change `PODINFO_UI_MESSAGE` with `kubectl set env` and run `kubectl get replicaset -l app=scout -w` in a second terminal. Write down how many pods the old and the new ReplicaSet have at each step, and check that the number of available pods never drops below 4.
- Change `maxSurge` to `0` and `maxUnavailable` to `1`, then roll out another change. Compare the steps with the first rollout.
- Run a loop of requests from `shuttle` during a rollout and count how many different `message` values you see.
- Point the image to a tag that does not exist, wait for `ProgressDeadlineExceeded`, and read the Deployment conditions. Then break the readiness probe path instead and compare the pod events.
- Roll back with `kubectl rollout undo`, then with `--to-revision`. Scale the Deployment before the undo and check that the replica count does not change.
- Set `minReadySeconds: 20` and measure how much longer the same rollout takes.
