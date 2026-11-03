#!/usr/bin/env bash
# Guard: both Rollouts, the client, go-httpbin and the Services still exist.
set -uo pipefail
fail=0
for pair in scout:4 shield:2; do
  n="${pair%%:*}"; want="${pair##*:}"
  r="$(kubectl -n starfleet get rollout "$n" -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  [ "$r" = "$want" ] || { echo "FAIL: rollout $n must exist with $want replicas (found '${r:-missing}')"; fail=1; }
done
for s in scout-stable scout-canary shield shield-preview; do
  kubectl -n starfleet get service $s >/dev/null 2>&1 || { echo "FAIL: service $s is missing"; fail=1; }
done
kubectl -n starfleet get deployment shuttle >/dev/null 2>&1 || { echo "FAIL: deployment shuttle is missing"; fail=1; }
kubectl -n analysis get deployment httpbin >/dev/null 2>&1 || { echo "FAIL: deployment httpbin in analysis is missing"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: both Rollouts, the Services, the client and go-httpbin exist"
exit "$fail"
