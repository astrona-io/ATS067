#!/usr/bin/env bash
# Check: the EventSource ref-hook and the Sensor ref-sensor patch deploy-state.
set -uo pipefail
fail=0
e="$(kubectl -n argo-events get eventsource ref-hook -o json 2>/dev/null)" || { echo "FAIL: EventSource ref-hook not found in argo-events"; exit 1; }
w="$(echo "$e" | jq -c '.spec.webhook.release // empty')"
[ -n "$w" ] || { echo "FAIL: spec.webhook must have an entry named release"; exit 1; }
[ "$(echo "$w" | jq -r '.port')" = "12000" ] || { echo "FAIL: the port of the entry release must be 12000"; fail=1; }
[ "$(echo "$w" | jq -r '.endpoint')" = "/release" ] || { echo "FAIL: the endpoint must be /release"; fail=1; }
[ "$(echo "$w" | jq -r '.method')" = "POST" ] || { echo "FAIL: the method must be POST"; fail=1; }
kubectl -n argo-events get service ref-hook-eventsource-svc >/dev/null 2>&1 || { echo "FAIL: Service ref-hook-eventsource-svc does not exist (add spec.service)"; fail=1; }
s="$(kubectl -n argo-events get sensor ref-sensor -o json 2>/dev/null)" || { echo "FAIL: Sensor ref-sensor not found in argo-events"; exit 1; }
echo "$s" | jq -e '[.spec.dependencies[]? | select(.eventSourceName=="ref-hook" and .eventName=="release")] | length >= 1' >/dev/null || { echo "FAIL: the Sensor needs a dependency on ref-hook and the event release"; fail=1; }
[ "$(echo "$s" | jq -r '.spec.template.serviceAccountName // ""')" = "sensor-runner" ] || { echo "FAIL: spec.template.serviceAccountName must be sensor-runner"; fail=1; }
t="$(echo "$s" | jq -c '[.spec.triggers[]?.template.k8s | select(.operation=="patch")][0] // empty')"
if [ -z "$t" ]; then echo "FAIL: no trigger uses k8s operation patch"; exit 1; fi
[ "$(echo "$t" | jq -r '.source.resource.metadata.name')" = "deploy-state" ] || { echo "FAIL: the trigger must target deploy-state"; fail=1; }
for k in body.service body.ref; do
  echo "$t" | jq -e --arg k "$k" '[.parameters[]? | select(.src.dataKey==$k)] | length >= 1' >/dev/null || { echo "FAIL: no parameter reads $k"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "PASS: the event source and the sensor are defined"
exit "$fail"
