# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/capstone/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: Release scout and read the failure

```sh
kubectl -n starfleet patch rollout scout --type json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-2"}]'
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Degraded rollout/scout --timeout=300s
kubectl -n starfleet get analysisrun -o jsonpath='{range .items[*]}{.metadata.name} {.status.phase}{"\n"}{end}'
```

The controller creates one canary pod and an AnalysisRun. The first measurement fails and the Rollout aborts. Read the run (use the name from the list above):

```sh
kubectl -n starfleet get analysisrun <run-name> -o yaml
```

Look at `status.metricResults`: the measured value is `95` (the score that the Rollout passed) and the condition of the template is `asInt(result) >= 990`. A score cannot reach 990, so every good release fails. The template is wrong, not the version.

## Step 2: Repair the template and release version-3

```sh
kubectl -n starfleet patch analysistemplate quality-gate --type json -p '[{"op":"replace","path":"/spec/metrics/0/successCondition","value":"asInt(result) >= 90"}]'
kubectl -n starfleet patch rollout scout --type json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-3"}]'
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Healthy rollout/scout --timeout=400s
```

The fix to the template does not restart the aborted release, because the template is not part of the pod template. A changed pod template creates a new revision. The new run takes three measurements with the value `95` and ends as `Successful`. Grade it; the checks `template-repaired` and `scout-released` pass.

## Step 3: Gate shield with a failing score

```sh
kubectl -n starfleet patch rollout shield --type json -p '[
 {"op":"add","path":"/spec/strategy/blueGreen/prePromotionAnalysis","value":{"templates":[{"templateName":"quality-gate"}],"args":[{"name":"score","value":"40"}]}},
 {"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-2"}]'
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Degraded rollout/shield --timeout=300s
```

The controller starts the new ReplicaSet and the preview Service selects it. Before the active Service switches, the analysis runs. The value `40` does not meet `asInt(result) >= 90`, so the run fails and the Rollout aborts. The Service `shield` keeps the selector of the stable ReplicaSet. Check it:

```sh
kubectl -n starfleet get rollout shield -o jsonpath='{.status.stableRS} {.status.currentPodHash}{"\n"}'
kubectl -n starfleet get service shield -o jsonpath='{.spec.selector.rollouts-pod-template-hash}{"\n"}'
```

The first value of the first line equals the output of the second command. Grade it; the check `shield-gated` passes.

## Step 4: Write the record

```sh
run="$(kubectl -n starfleet get analysisrun -o json | jq -r '[.items[] | select(any(.metadata.ownerReferences[]?; .kind=="Rollout" and .name=="shield")) | select(.status.phase=="Failed")][0].metadata.name')"
kubectl -n starfleet create configmap analysis-record \
  --from-literal=scout-stable-rs="$(kubectl -n starfleet get rollout scout -o jsonpath='{.status.stableRS}')" \
  --from-literal=shield-stable-rs="$(kubectl -n starfleet get rollout shield -o jsonpath='{.status.stableRS}')" \
  --from-literal=failed-run="$run" \
  --from-literal=observed-at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

Grade the whole lab. All five checks pass.
