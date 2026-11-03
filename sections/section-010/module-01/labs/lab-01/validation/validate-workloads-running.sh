#!/usr/bin/env bash
# Guard: the Deployments still exist and keep their replica counts. It passes
# before any change and fails when a learner deletes or scales a workload.
set -uo pipefail
fail=0
check() { # name expected-replicas
  local replicas
  replicas="$(kubectl -n starfleet get deployment "$1" -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  if [ "$replicas" != "$2" ]; then
    echo "FAIL: deployment $1 must exist with $2 replicas (found '${replicas:-missing}')"
    fail=1
  fi
}
check scout 3
check probe 2
check shuttle 1
[ "$fail" -eq 0 ] && echo "PASS: scout, probe and shuttle exist with their replica counts"
exit "$fail"
