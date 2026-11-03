#!/usr/bin/env bash
# Check: the ConfigMap sync-record matches the Application and the Deployment.
set -uo pipefail
fail=0
NS=starfleet
NAME=sync-record
kubectl -n $NS get configmap $NAME >/dev/null 2>&1 || { echo "FAIL: ConfigMap $NAME not found in $NS"; exit 1; }
read_key() { kubectl -n $NS get configmap $NAME -o json | jq -r --arg key "$1" '.data[$key] // ""'; }
rev="$(kubectl -n argocd get application scout -o jsonpath='{.status.sync.revision}')"
rec="$(read_key synced-revision)"
{ [ -n "$rec" ] && [ "$rec" = "$rev" ]; } || { echo "FAIL: key synced-revision is '$rec', the Application revision is '$rev'"; fail=1; }
live="$(kubectl -n $NS get deployment scout -o jsonpath='{.spec.replicas}')"
rec="$(read_key replicas)"
{ [ -n "$rec" ] && [ "$rec" = "$live" ]; } || { echo "FAIL: key replicas is '$rec', the Deployment has '$live'"; fail=1; }
echo "$(read_key observed-at)" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' || { echo "FAIL: key observed-at must be a UTC time like 2026-11-03T10:15:00Z"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the sync record matches the cluster"
exit "$fail"
