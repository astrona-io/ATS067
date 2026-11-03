#!/usr/bin/env bash
# Guard: the Deployments still exist and are available.
set -uo pipefail
fail=0
for name in ledger flagcheck; do
  available="$(kubectl -n starfleet get deployment "$name" -o jsonpath="{.status.availableReplicas}" 2>/dev/null)"
  if [ -z "$available" ] || [ "$available" = "0" ]; then
    echo "FAIL: deployment $name must exist and have an available replica"
    fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "PASS: ledger and flagcheck are running"
exit "$fail"
