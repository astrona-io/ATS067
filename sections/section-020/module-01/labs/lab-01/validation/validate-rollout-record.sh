#!/usr/bin/env bash
# Check: the ConfigMap rollout-record matches the live Rollouts and Services.
set -uo pipefail
fail=0
NS=starfleet
NAME=rollout-record
kubectl -n $NS get configmap $NAME >/dev/null 2>&1 || { echo "FAIL: ConfigMap $NAME not found in $NS"; exit 1; }
read_key() { kubectl -n $NS get configmap $NAME -o json | jq -r --arg key "$1" '.data[$key] // ""'; }

stable="$(kubectl -n $NS get rollout scout -o jsonpath='{.status.stableRS}')"
recorded="$(read_key scout-stable-rs)"
if [ -z "$recorded" ] || [ "$recorded" != "$stable" ]; then
  echo "FAIL: key scout-stable-rs is '$recorded', status.stableRS of scout is '$stable'"
  fail=1
fi
active="$(kubectl -n $NS get service shield-active -o jsonpath='{.spec.selector.rollouts-pod-template-hash}')"
recorded="$(read_key shield-active-hash)"
if [ -z "$recorded" ] || [ "$recorded" != "$active" ]; then
  echo "FAIL: key shield-active-hash is '$recorded', the selector of shield-active has '$active'"
  fail=1
fi
observed="$(read_key observed-at)"
echo "$observed" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' || { echo "FAIL: key observed-at must be a UTC time like 2026-11-03T10:15:00Z"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the rollout record matches the cluster"
exit "$fail"
