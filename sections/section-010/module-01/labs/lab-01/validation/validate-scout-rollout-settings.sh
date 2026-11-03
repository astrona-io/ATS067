#!/usr/bin/env bash
# Check: scout keeps full capacity during a rollout and waits for stable pods.
set -uo pipefail
fail=0
d="$(kubectl -n starfleet get deployment scout -o json 2>/dev/null)" || { echo "FAIL: deployment scout not found"; exit 1; }

type="$(echo "$d" | jq -r '.spec.strategy.type')"
surge="$(echo "$d" | jq -r '.spec.strategy.rollingUpdate.maxSurge // "" | tostring')"
unavailable="$(echo "$d" | jq -r '.spec.strategy.rollingUpdate.maxUnavailable // "" | tostring')"
if [ "$type" != "RollingUpdate" ] || [ "$surge" != "1" ] || [ "$unavailable" != "0" ]; then
  echo "FAIL: strategy must be RollingUpdate with maxSurge 1 and maxUnavailable 0 (found $type surge=$surge unavailable=$unavailable)"
  fail=1
fi
min_ready="$(echo "$d" | jq -r '.spec.minReadySeconds // 0')"
if [ "$min_ready" -lt 5 ]; then
  echo "FAIL: minReadySeconds must be at least 5, found $min_ready"
  fail=1
fi
deadline="$(echo "$d" | jq -r '.spec.progressDeadlineSeconds // 600')"
if [ "$deadline" -gt 180 ]; then
  echo "FAIL: progressDeadlineSeconds must be 180 or less, found $deadline"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: scout uses maxSurge 1, maxUnavailable 0, minReadySeconds $min_ready and a deadline of $deadline seconds"
exit "$fail"
