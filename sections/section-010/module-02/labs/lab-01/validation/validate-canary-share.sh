#!/usr/bin/env bash
# Check: the Service probe reaches the stable pods and exactly one canary
# pod, so that the canary share is 25 percent.
set -uo pipefail
fail=0
# Prints the value of the track label of every ready endpoint of a Service,
# one per line. Reads the EndpointSlices and the pods.
tracks_behind() {
  local pods
  pods="$(kubectl -n starfleet get endpointslices -l kubernetes.io/service-name="$1" -o json \
    | jq -r ".items[].endpoints[]? | select(.conditions.ready == true) | .targetRef.name")"
  [ -z "$pods" ] && return 0
  for pod in $pods; do
    kubectl -n starfleet get pod "$pod" -o jsonpath="{.metadata.labels.track}{\"\\n\"}" 2>/dev/null
  done
}

all="$(tracks_behind probe)"
stable="$(echo "$all" | grep -c "^stable$" || true)"
canary="$(echo "$all" | grep -c "^canary$" || true)"
total="$(echo "$all" | grep -c . || true)"
if [ "$stable" != "3" ] || [ "$canary" != "1" ] || [ "$total" != "4" ]; then
  echo "FAIL: probe must have 3 stable and 1 canary ready endpoints (found stable=$stable canary=$canary total=$total)"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: probe has 3 stable and 1 canary endpoint, a canary share of 25 percent"
exit "$fail"
