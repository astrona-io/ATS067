#!/usr/bin/env bash
# Check: intruder is in crew, its destination was not edited, and the project
# refuses it (condition InvalidSpecError).
set -uo pipefail
fail=0
a="$(kubectl -n argocd get application intruder -o json 2>/dev/null)" || { echo "FAIL: Application intruder not found"; exit 1; }
[ "$(echo "$a" | jq -r '.spec.project')" = "crew" ] || { echo "FAIL: intruder is in project '$(echo "$a" | jq -r '.spec.project')', expected crew"; fail=1; }
[ "$(echo "$a" | jq -r '.spec.destination.namespace')" = "vault" ] || { echo "FAIL: the destination namespace of intruder must stay vault"; fail=1; }
[ "$(echo "$a" | jq -r '[.status.conditions[]? | select(.type=="InvalidSpecError")] | length')" != "0" ] || { echo "FAIL: intruder has no InvalidSpecError condition yet (the project must refuse its destination)"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the project crew refuses intruder"
exit "$fail"
