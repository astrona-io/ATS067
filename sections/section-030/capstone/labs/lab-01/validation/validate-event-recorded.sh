#!/usr/bin/env bash
# Check: deploy-state holds the service and the head commit of main, set by a
# patch (no generated copies).
set -uo pipefail
fail=0
REPO=/var/lib/gitea/git/repositories/starfleet/fleet-config.git
head="$(kubectl -n gitea exec deploy/gitea -- git --git-dir="$REPO" rev-parse main 2>/dev/null)"
c="$(kubectl -n starfleet get configmap deploy-state -o json 2>/dev/null)" || { echo "FAIL: ConfigMap deploy-state not found"; exit 1; }
[ "$(echo "$c" | jq -r '.data.service // ""')" = "scout" ] || { echo "FAIL: deploy-state data.service is '$(echo "$c" | jq -r '.data.service // ""')', expected scout"; fail=1; }
ref="$(echo "$c" | jq -r '.data.ref // ""')"
{ [ -n "$head" ] && [ "$ref" = "$head" ]; } || { echo "FAIL: deploy-state data.ref is '$ref', the head of main is '$head'"; fail=1; }
extra="$(kubectl -n starfleet get configmap -o json | jq '[.items[] | select(.metadata.name | startswith("deploy-event-"))] | length')"
[ "$extra" = "0" ] || { echo "FAIL: generated ConfigMaps deploy-event-* exist"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: deploy-state holds scout and the head commit of main"
exit "$fail"
