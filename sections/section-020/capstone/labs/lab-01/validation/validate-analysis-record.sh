#!/usr/bin/env bash
# Check: the ConfigMap analysis-record matches the live Rollouts and runs.
set -uo pipefail
fail=0
NS=starfleet
NAME=analysis-record
kubectl -n $NS get configmap $NAME >/dev/null 2>&1 || { echo "FAIL: ConfigMap $NAME not found in $NS"; exit 1; }
read_key() { kubectl -n $NS get configmap $NAME -o json | jq -r --arg key "$1" '.data[$key] // ""'; }
for pair in "scout-stable-rs:scout" "shield-stable-rs:shield"; do
  key="${pair%%:*}"; ro="${pair##*:}"
  live="$(kubectl -n $NS get rollout "$ro" -o jsonpath='{.status.stableRS}')"
  rec="$(read_key "$key")"
  { [ -n "$rec" ] && [ "$rec" = "$live" ]; } || { echo "FAIL: key $key is '$rec', status.stableRS of $ro is '$live'"; fail=1; }
done
run="$(read_key failed-run)"
if [ -z "$run" ]; then
  echo "FAIL: key failed-run is empty"; fail=1
else
  ok="$(kubectl -n $NS get analysisrun "$run" -o json 2>/dev/null | jq -r 'select(.status.phase=="Failed") | select(any(.metadata.ownerReferences[]?; .kind=="Rollout" and .name=="shield")) | .metadata.name')"
  [ "$ok" = "$run" ] || { echo "FAIL: failed-run '$run' is not a Failed AnalysisRun of shield"; fail=1; }
fi
echo "$(read_key observed-at)" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' || { echo "FAIL: key observed-at must be a UTC time like 2026-11-03T10:15:00Z"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the analysis record matches the cluster"
exit "$fail"
