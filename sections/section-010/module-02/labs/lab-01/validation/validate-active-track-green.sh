#!/usr/bin/env bash
# Check: the active Service scout sends traffic to green only, and blue is
# still running with all its replicas so that a switch back is possible.
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

tracks="$(tracks_behind scout | sort | uniq -c | tr -s " " | tr "\n" ";")"
green="$(tracks_behind scout | grep -c "^green$" || true)"
other="$(tracks_behind scout | grep -vc "^green$" || true)"
if [ "$green" != "2" ] || [ "$other" != "0" ]; then
  echo "FAIL: scout must have exactly the 2 green pods as ready endpoints (found: $tracks)"
  fail=1
fi
blue_available="$(kubectl -n starfleet get deployment scout-blue -o jsonpath="{.status.availableReplicas}" 2>/dev/null)"
if [ "${blue_available:-0}" != "2" ]; then
  echo "FAIL: scout-blue must keep 2 available replicas for a switch back (found ${blue_available:-0})"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: scout serves green and blue is ready for a switch back"
exit "$fail"
