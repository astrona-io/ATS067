#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
NS=starfleet

kubectl -n $NS apply -f - <<'YAML'
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

# Release 1: a bad score. The analysis fails and the release aborts.
kubectl -n $NS patch rollout scout --type json -p '[
 {"op":"add","path":"/spec/strategy/canary/analysis","value":{"templates":[{"templateName":"quality-gate"}],"args":[{"name":"score","value":"40"}]}},
 {"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-bad"}]'
kubectl -n $NS wait --for=jsonpath='{.status.phase}'=Degraded rollout/scout --timeout=300s

# Release 2: a good score and a new template. The analysis succeeds.
kubectl -n $NS patch rollout scout --type json -p '[
 {"op":"replace","path":"/spec/strategy/canary/analysis/args/0/value","value":"95"},
 {"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-3"}]'
kubectl -n $NS wait --for=jsonpath='{.status.phase}'=Healthy rollout/scout --timeout=400s
echo "[solution] Applied."
