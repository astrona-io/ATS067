#!/usr/bin/env bash
# Check: the EventSource fleet-hook has the webhook entry deploy and a Service.
set -uo pipefail
fail=0
e="$(kubectl -n argo-events get eventsource fleet-hook -o json 2>/dev/null)" || { echo "FAIL: EventSource fleet-hook not found in argo-events"; exit 1; }
w="$(echo "$e" | jq -c '.spec.webhook.deploy // empty')"
if [ -z "$w" ]; then
  echo "FAIL: spec.webhook must have an entry named deploy"; exit 1
fi
[ "$(echo "$w" | jq -r '.port')" = "12000" ] || { echo "FAIL: the port of the entry deploy must be 12000"; fail=1; }
[ "$(echo "$w" | jq -r '.endpoint')" = "/deploy" ] || { echo "FAIL: the endpoint must be /deploy"; fail=1; }
[ "$(echo "$w" | jq -r '.method')" = "POST" ] || { echo "FAIL: the method must be POST"; fail=1; }
[ "$(echo "$e" | jq -r '[.spec.service.ports[]? | select(.port==12000)] | length')" -ge 1 ] || { echo "FAIL: spec.service must expose port 12000"; fail=1; }
kubectl -n argo-events get service fleet-hook-eventsource-svc >/dev/null 2>&1 || { echo "FAIL: Service fleet-hook-eventsource-svc does not exist yet"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the EventSource fleet-hook has the webhook entry deploy and a Service"
exit "$fail"
