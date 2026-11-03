#!/usr/bin/env bash
# Check: the ConfigMap release-evidence matches what the cluster does now.
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

NS=starfleet
NAME=release-evidence
if ! kubectl -n $NS get configmap $NAME >/dev/null 2>&1; then
  echo "FAIL: ConfigMap $NAME not found in $NS"
  exit 1
fi
read_key() { kubectl -n $NS get configmap $NAME -o json | jq -r --arg key "$1" ".data[\$key] // \"\""; }
active="$(read_key active-track)"
live_active="$(tracks_behind scout | sort -u | head -n 1)"
if [ -z "$active" ] || [ "$active" != "$live_active" ]; then
  echo "FAIL: key active-track is \"$active\", the Service scout serves \"$live_active\""
  fail=1
fi
percent="$(read_key canary-percent)"
all="$(tracks_behind probe)"
total="$(echo "$all" | grep -c . || true)"
canary="$(echo "$all" | grep -c "^canary$" || true)"
live_percent=0
[ "$total" -gt 0 ] && live_percent=$(( canary * 100 / total ))
if [ "$percent" != "$live_percent" ]; then
  echo "FAIL: key canary-percent is \"$percent\", the endpoints of probe give $live_percent"
  fail=1
fi
observed="$(read_key observed-at)"
if ! echo "$observed" | grep -Eq "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"; then
  echo "FAIL: key observed-at must be a UTC time like 2026-11-03T10:15:00Z"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: the release evidence matches the cluster"
exit "$fail"
