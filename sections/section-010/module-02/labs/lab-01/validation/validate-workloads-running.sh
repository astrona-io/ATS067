#!/usr/bin/env bash
# Guard: the Deployments still exist and keep their replica counts.
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

check() {
  local replicas
  replicas="$(kubectl -n starfleet get deployment "$1" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
  if [ "$replicas" != "$2" ] && [ "${3:-}" != "any" ]; then
    echo "FAIL: deployment $1 must exist with $2 replicas (found \"${replicas:-missing}\")"
    fail=1
  fi
}
check scout-blue 2
check scout-green 2
check probe-stable 3
check shuttle 1
kubectl -n starfleet get deployment probe-canary >/dev/null 2>&1 || { echo "FAIL: deployment probe-canary is missing"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: all Deployments exist with their replica counts"
exit "$fail"
