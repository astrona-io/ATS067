# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-02/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: Check the measured endpoint

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s 'http://httpbin.analysis.svc.cluster.local:8080/get?score=95'
```

The JSON answer has the field `args`, and the value of `score` is a list that holds the text `95`. The path `{$.args.score[0]}` selects it.

## Step 2: Create the template

```sh
kubectl -n starfleet apply -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: quality-gate
spec:
  args:
    - name: score
  metrics:
    - name: quality
      interval: 10s
      count: 3
      failureLimit: 0
      successCondition: asInt(result) >= 90
      provider:
        web:
          url: "http://httpbin.analysis.svc.cluster.local:8080/get?score={{ args.score }}"
          jsonPath: "{$.args.score[0]}"
YAML
```

Grade it; the check `quality-gate-template` passes. A template alone does nothing: no run exists yet.

## Step 3: Release a bad version

Add the analysis and change the template in one patch, so that one release uses both:

```sh
kubectl -n starfleet patch rollout scout --type json -p '[
 {"op":"add","path":"/spec/strategy/canary/analysis","value":{"templates":[{"templateName":"quality-gate"}],"args":[{"name":"score","value":"40"}]}},
 {"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-bad"}]'
kubectl -n starfleet get analysisrun
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Degraded rollout/scout --timeout=300s
```

The controller creates one canary pod, starts an `AnalysisRun` and takes the first measurement. The value `40` does not meet `asInt(result) >= 90` and the failure limit is 0, so the run is `Failed`. The Rollout aborts: the canary is scaled down, the phase is `Degraded` and the 4 old pods keep serving.

```sh
kubectl -n starfleet get analysisrun -o jsonpath='{range .items[*]}{.metadata.name} {.status.phase}{"\n"}{end}'
kubectl -n starfleet get rollout scout -o jsonpath='{.status.phase} {.status.abort} {.status.stableRS} {.status.currentPodHash}{"\n"}'
```

The two hashes differ. Grade it; the check `bad-release-aborted` passes.

## Step 4: Release a good version

Changing only the argument does not start a release, because it is not part of the pod template. Change both:

```sh
kubectl -n starfleet patch rollout scout --type json -p '[
 {"op":"replace","path":"/spec/strategy/canary/analysis/args/0/value","value":"95"},
 {"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-3"}]'
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Healthy rollout/scout --timeout=400s
```

The run takes three measurements with the value `95` and ends as `Successful`. The steps finish and `status.stableRS` equals `status.currentPodHash`. Grade the whole lab. All four checks pass.
