#!/usr/bin/env bash
# Check: the ConfigMap release-record holds the live revision of both
# Deployments and a UTC time.
set -uo pipefail
fail=0
NS=starfleet
NAME=release-record

if ! kubectl -n $NS get configmap $NAME >/dev/null 2>&1; then
  echo "FAIL: ConfigMap $NAME not found in $NS"
  exit 1
fi
read_key() { kubectl -n $NS get configmap $NAME -o json | jq -r --arg key "$1" '.data[$key] // ""'; }
live_revision() { kubectl -n $NS get deployment "$1" -o json | jq -r '.metadata.annotations["deployment.kubernetes.io/revision"] // ""'; }

for pair in "warp-revision:warp" "impulse-revision:impulse"; do
  key="${pair%%:*}"; dep="${pair##*:}"
  recorded="$(read_key "$key")"
  live="$(live_revision "$dep")"
  if [ -z "$recorded" ] || [ "$recorded" != "$live" ]; then
    echo "FAIL: key '$key' is '$recorded', the live revision of $dep is '$live'"
    fail=1
  fi
done
track="$(read_key shield-track)"
live_track="$(kubectl -n $NS get endpointslices -l kubernetes.io/service-name=shield -o json | jq -r ".items[].endpoints[]? | select(.conditions.ready == true) | .targetRef.name" | head -n 1 | xargs -I{} kubectl -n $NS get pod {} -o jsonpath="{.metadata.labels.track}")"
if [ -z "$track" ] || [ "$track" != "$live_track" ]; then
  echo "FAIL: key shield-track is '$track', the Service shield serves '$live_track'"
  fail=1
fi
observed="$(read_key observed-at)"
if ! echo "$observed" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'; then
  echo "FAIL: key 'observed-at' must be a UTC time like 2026-11-03T10:15:00Z"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: the release record matches the live revisions"
exit "$fail"
