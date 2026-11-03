# Question

Solve this question on: `terminal`

The Argo Rollouts controller runs in `argo-rollouts`. The server `go-httpbin` runs in the namespace `analysis` and answers on `http://httpbin.analysis.svc.cluster.local:8080`. In `starfleet`, the canary Rollout `scout` runs version 1 (message `version-1`). Do not delete or scale a Rollout.

1. Create an `AnalysisTemplate` named `quality-gate` in `starfleet`:
   - It declares the argument `score` without a default.
   - It has one metric named `quality` with the `web` provider. The URL is `http://httpbin.analysis.svc.cluster.local:8080/get?score=` followed by the argument `score`. The `jsonPath` is `{$.args.score[0]}`.
   - The success condition is `asInt(result) >= 90`.
   - The interval is `10s`, the count is `3` and the failure limit is `0`.

2. Add a background analysis to the canary strategy of `scout` that uses `quality-gate`. Release a changed template (the message `version-bad`) with the argument `score` set to `40`. The analysis must fail and the release must abort, so that the version 1 pods keep serving.

3. Release again with a changed template (the message `version-3`) and the argument `score` set to `95`. Wait until `scout` is `Healthy` with 4 pods that run `version-3`.

`kubectl` already points at the cluster as the cluster administrator. The Argo Rollouts kubectl plugin is not installed.

Check your work with `astrona submit`.
