#!/usr/bin/env bash
# Check: an event reached deploy-state through the Sensor, and the action is
# a patch of one object (no generated copies).
set -uo pipefail
fail=0
c="$(kubectl -n starfleet get configmap deploy-state -o json 2>/dev/null)" || { echo "FAIL: ConfigMap deploy-state not found"; exit 1; }
[ "$(echo "$c" | jq -r '.data.service // ""')" = "scout" ] || { echo "FAIL: deploy-state data.service is '$(echo "$c" | jq -r '.data.service // ""')', expected scout"; fail=1; }
[ "$(echo "$c" | jq -r '.data.ref // ""')" = "main" ] || { echo "FAIL: deploy-state data.ref is '$(echo "$c" | jq -r '.data.ref // ""')', expected main"; fail=1; }
extra="$(kubectl -n starfleet get configmap -o json | jq '[.items[] | select(.metadata.name | startswith("deploy-event-"))] | length')"
[ "$extra" = "0" ] || { echo "FAIL: $extra generated ConfigMaps deploy-event-* exist; the action must patch deploy-state"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the event updated deploy-state"
exit "$fail"
