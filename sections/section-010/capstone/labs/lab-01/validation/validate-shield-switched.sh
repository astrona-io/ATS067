#!/usr/bin/env bash
# Check: the Service shield sends traffic to the green pods only, and blue
# stays ready for a switch back.
set -uo pipefail
fail=0
NS=starfleet

pods="$(kubectl -n $NS get endpointslices -l kubernetes.io/service-name=shield -o json \
  | jq -r '.items[].endpoints[]? | select(.conditions.ready == true) | .targetRef.name')"
green=0
other=0
for pod in $pods; do
  track="$(kubectl -n $NS get pod "$pod" -o jsonpath='{.metadata.labels.track}' 2>/dev/null)"
  if [ "$track" = "green" ]; then green=$((green + 1)); else other=$((other + 1)); fi
done
if [ "$green" != "2" ] || [ "$other" != "0" ]; then
  echo "FAIL: shield must have exactly the 2 green pods as ready endpoints (found green=$green other=$other)"
  fail=1
fi
blue="$(kubectl -n $NS get deployment shield-blue -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ "${blue:-0}" != "2" ]; then
  echo "FAIL: shield-blue must keep 2 available replicas (found ${blue:-0})"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: shield serves green and blue is ready for a switch back"
exit "$fail"
