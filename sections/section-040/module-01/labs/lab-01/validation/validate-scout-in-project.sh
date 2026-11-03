#!/usr/bin/env bash
# Check: scout belongs to crew and is still synced and healthy.
set -uo pipefail
fail=0
a="$(kubectl -n argocd get application scout -o json 2>/dev/null)" || { echo "FAIL: Application scout not found"; exit 1; }
[ "$(echo "$a" | jq -r '.spec.project')" = "crew" ] || { echo "FAIL: scout is in project '$(echo "$a" | jq -r '.spec.project')', expected crew"; fail=1; }
[ "$(echo "$a" | jq -r '.status.sync.status')" = "Synced" ] || { echo "FAIL: scout is not Synced"; fail=1; }
[ "$(echo "$a" | jq -r '.status.health.status')" = "Healthy" ] || { echo "FAIL: scout is not Healthy"; fail=1; }
[ "$(echo "$a" | jq -r '[.status.conditions[]? | select(.type=="InvalidSpecError")] | length')" = "0" ] || { echo "FAIL: scout has an InvalidSpecError condition"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: scout is in crew and is Synced and Healthy"
exit "$fail"
