#!/usr/bin/env bash
# Guard: the Rollouts and the client still exist with their replica counts.
set -uo pipefail
fail=0
for pair in "scout:4" "shield:4"; do
  r="$(kubectl -n starfleet get rollout "${pair%%:*}" -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  if [ "$r" != "${pair##*:}" ]; then echo "FAIL: rollout ${pair%%:*} must exist with ${pair##*:} replicas (found '${r:-missing}')"; fail=1; fi
done
kubectl -n starfleet get deployment shuttle >/dev/null 2>&1 || { echo "FAIL: deployment shuttle is missing"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: scout, shield and shuttle exist with their replica counts"
exit "$fail"
