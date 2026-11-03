#!/usr/bin/env bash
# Check: the Application has automated sync with prune and self-heal.
set -uo pipefail
fail=0
a="$(kubectl -n argocd get application scout -o json 2>/dev/null)" || { echo "FAIL: Application scout not found"; exit 1; }
[ "$(echo "$a" | jq -r '.spec.syncPolicy.automated // empty | type')" = "object" ] || { echo "FAIL: spec.syncPolicy.automated is missing"; fail=1; }
[ "$(echo "$a" | jq -r '.spec.syncPolicy.automated.prune // false')" = "true" ] || { echo "FAIL: automated.prune must be true"; fail=1; }
[ "$(echo "$a" | jq -r '.spec.syncPolicy.automated.selfHeal // false')" = "true" ] || { echo "FAIL: automated.selfHeal must be true"; fail=1; }
[ "$(echo "$a" | jq -r '.spec.source.path')" = "apps/scout" ] || { echo "FAIL: spec.source.path must stay apps/scout"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: automated sync with prune and self-heal is on"
exit "$fail"
