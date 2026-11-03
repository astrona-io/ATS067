#!/usr/bin/env bash
# Check: the Sensor fleet-sensor filters on main and patches deploy-state.
set -uo pipefail
fail=0
s="$(kubectl -n argo-events get sensor fleet-sensor -o json 2>/dev/null)" || { echo "FAIL: Sensor fleet-sensor not found in argo-events"; exit 1; }
dep="$(echo "$s" | jq -c '[.spec.dependencies[]? | select(.eventSourceName=="fleet-hook" and .eventName=="deploy")][0] // empty')"
if [ -z "$dep" ]; then
  echo "FAIL: the Sensor needs a dependency on eventSourceName fleet-hook and eventName deploy"; exit 1
fi
echo "$dep" | jq -e '[.filters.data[]? | select(.path=="body.ref") | .value[]?] | index("main") != null' >/dev/null || { echo "FAIL: the dependency needs a data filter on body.ref with the value main"; fail=1; }
[ "$(echo "$s" | jq -r '.spec.template.serviceAccountName // ""')" = "sensor-runner" ] || { echo "FAIL: spec.template.serviceAccountName must be sensor-runner"; fail=1; }
t="$(echo "$s" | jq -c '[.spec.triggers[]?.template.k8s | select(.operation=="patch")][0] // empty')"
if [ -z "$t" ]; then
  echo "FAIL: no trigger uses k8s operation patch"; exit 1
fi
[ "$(echo "$t" | jq -r '.source.resource.kind')" = "ConfigMap" ] || { echo "FAIL: the trigger must patch a ConfigMap"; fail=1; }
[ "$(echo "$t" | jq -r '.source.resource.metadata.name')" = "deploy-state" ] || { echo "FAIL: the trigger must target the name deploy-state"; fail=1; }
[ "$(echo "$t" | jq -r '.source.resource.metadata.namespace')" = "starfleet" ] || { echo "FAIL: the trigger must target the namespace starfleet"; fail=1; }
for k in body.service body.ref; do
  echo "$t" | jq -e --arg k "$k" '[.parameters[]? | select(.src.dataKey==$k)] | length >= 1' >/dev/null || { echo "FAIL: no parameter reads $k"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "PASS: the Sensor filters on main and patches deploy-state"
exit "$fail"
