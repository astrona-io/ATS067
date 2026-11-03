# Question

Solve this question on: `terminal`

The Argo Rollouts controller runs in `argo-rollouts`. The server `go-httpbin` runs in the namespace `analysis` and answers on `http://httpbin.analysis.svc.cluster.local:8080`. In `starfleet`, two Rollouts run version 1: the canary Rollout `scout` and the blue-green Rollout `shield`. The AnalysisTemplate `quality-gate` reads the field `args.score[0]` from `/get?score=<score>` and `scout` already uses it as a background analysis with the argument `score` set to `95`. Do not delete or scale a Rollout or a Service.

1. Release a changed template of `scout` (the message `version-2`). The analysis fails although the score is good. Find out why from the AnalysisRun, then repair the template `quality-gate` so that a score of 95 passes and a score of 40 still fails. Keep the metric name, the URL, the `jsonPath` and the failure limit.

2. Release `scout` again with a changed template (the message `version-3`). Wait until `scout` is `Healthy` with 4 pods that run `version-3`.

3. Add a `prePromotionAnalysis` to `shield` that uses `quality-gate` with the argument `score` set to `40`. Release a changed template of `shield` (the message `version-2`). The analysis must fail, and the Service `shield` must keep selecting the stable ReplicaSet.

4. Create a ConfigMap named `analysis-record` in `starfleet` with these keys:
   - `scout-stable-rs`: `status.stableRS` of `scout`
   - `shield-stable-rs`: `status.stableRS` of `shield`
   - `failed-run`: the name of the Failed AnalysisRun of `shield`
   - `observed-at`: the current UTC time like `2026-11-03T10:15:00Z`

`kubectl` already points at the cluster as the cluster administrator. The Argo Rollouts kubectl plugin is not installed.

Check your work with `astrona submit`.
