# Overview: AnalysisTemplate And AnalysisRun Decisions (Playground)

This is a **playground**, not a lab. It starts a cluster with the Argo Rollouts controller, an endpoint to measure and a canary Rollout, then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.
- The Argo Rollouts controller v1.10.0 in `argo-rollouts`. The kubectl plugin is not installed.
- In the namespace `analysis`: `go-httpbin` (Service `httpbin`, port 8080), the endpoint that the template measures.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | AnalysisTemplate `quality-gate` | Argument `score`, one web metric that reads `args.score[0]` from `/get?score=<score>`, success when `asInt(result) >= 90`, 3 measurements every 10 seconds, failure limit 0 |
  | Rollout `scout` | Canary, 4 replicas, steps 25, pause 20s, 50, pause 20s. It has no analysis yet |
  | Services `scout-stable`, `scout-canary` | The stable and canary Services |
  | Deployment `shuttle` | One `curl` pod |

## Try the endpoint

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s 'http://httpbin.analysis.svc.cluster.local:8080/get?score=95'
```

## Practice tasks

- Add a background analysis to `scout` with `kubectl patch` and the argument `score` set to `95`. Change the message and watch `kubectl -n starfleet get analysisrun -w`.
- Repeat with `score` set to `40` and read the phase of the Rollout, `status.abort` and the two hashes.
- Change the template to `failureLimit: 2` and compare when a bad score fails the run.
- Add `failureCondition: asInt(result) < 50` and try the score `70`. Read the phase of the run.
- Change the `jsonPath` to a field that does not exist and read the phase of the run.
- Move the analysis from the background to an inline step after `setWeight: 25` and compare the timing.
- Read the measurements of a run with `kubectl get analysisrun <name> -o yaml`.
