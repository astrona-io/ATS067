#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
NS=starfleet

# Release scout version-2 with the broken template: the analysis fails.
kubectl -n $NS patch rollout scout --type json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-2"}]'
kubectl -n $NS wait --for=jsonpath='{.status.phase}'=Degraded rollout/scout --timeout=300s

# Repair the template, then release version-3.
kubectl -n $NS patch analysistemplate quality-gate --type json -p '[{"op":"replace","path":"/spec/metrics/0/successCondition","value":"asInt(result) >= 90"}]'
kubectl -n $NS patch rollout scout --type json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-3"}]'
kubectl -n $NS wait --for=jsonpath='{.status.phase}'=Healthy rollout/scout --timeout=400s

# shield: gate the promotion with a score that fails.
kubectl -n $NS patch rollout shield --type json -p '[
 {"op":"add","path":"/spec/strategy/blueGreen/prePromotionAnalysis","value":{"templates":[{"templateName":"quality-gate"}],"args":[{"name":"score","value":"40"}]}},
 {"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-2"}]'
kubectl -n $NS wait --for=jsonpath='{.status.phase}'=Degraded rollout/shield --timeout=300s

run="$(kubectl -n $NS get analysisrun -o json | jq -r '[.items[] | select(any(.metadata.ownerReferences[]?; .kind=="Rollout" and .name=="shield")) | select(.status.phase=="Failed")][0].metadata.name')"
kubectl -n $NS create configmap analysis-record \
  --from-literal=scout-stable-rs="$(kubectl -n $NS get rollout scout -o jsonpath='{.status.stableRS}')" \
  --from-literal=shield-stable-rs="$(kubectl -n $NS get rollout shield -o jsonpath='{.status.stableRS}')" \
  --from-literal=failed-run="$run" \
  --from-literal=observed-at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "[solution] Applied."
