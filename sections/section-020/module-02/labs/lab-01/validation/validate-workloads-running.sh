#!/usr/bin/env bash
# Guard: the Rollout, the client and go-httpbin still exist.
set -uo pipefail
fail=0
r="$(kubectl -n starfleet get rollout scout -o jsonpath='{.spec.replicas}' 2>/dev/null)"
[ "$r" = "4" ] || { echo "FAIL: rollout scout must exist with 4 replicas (found '${r:-missing}')"; fail=1; }
kubectl -n starfleet get deployment shuttle >/dev/null 2>&1 || { echo "FAIL: deployment shuttle is missing"; fail=1; }
kubectl -n analysis get deployment httpbin >/dev/null 2>&1 || { echo "FAIL: deployment httpbin in analysis is missing"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: scout, shuttle and httpbin exist"
exit "$fail"
