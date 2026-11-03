#!/usr/bin/env bash
# Check: after the failed release, a release with score 95 succeeded and scout
# is Healthy on version-3.
set -uo pipefail
fail=0
r="$(kubectl -n starfleet get rollout scout -o json 2>/dev/null)" || { echo "FAIL: rollout scout not found"; exit 1; }

message="$(echo "$r" | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="PODINFO_UI_MESSAGE") | .value')"
[ "$message" = "version-3" ] || { echo "FAIL: the template must have the message version-3 (found '$message')"; fail=1; }
score="$(echo "$r" | jq -r '.spec.strategy.canary.analysis.args[]? | select(.name=="score") | .value')"
[ "$score" = "95" ] || { echo "FAIL: the analysis argument score must be 95 (found '$score')"; fail=1; }
phase="$(echo "$r" | jq -r '.status.phase // ""')"
stable="$(echo "$r" | jq -r '.status.stableRS // ""')"
current="$(echo "$r" | jq -r '.status.currentPodHash // ""')"
if [ "$phase" != "Healthy" ] || [ -z "$stable" ] || [ "$stable" != "$current" ]; then
  echo "FAIL: the release is not complete (phase=$phase stableRS=$stable currentPodHash=$current)"
  fail=1
fi
ready="$(kubectl -n starfleet get pods -l app=scout -o json | jq '[.items[] | select(.metadata.deletionTimestamp == null) | select(any(.spec.containers[0].env[]?; .name=="PODINFO_UI_MESSAGE" and .value=="version-3")) | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length')"
[ "$ready" = "4" ] || { echo "FAIL: $ready ready pods run version-3, expected 4"; fail=1; }

runs="$(kubectl -n starfleet get analysisrun -o json)"
ok="$(echo "$runs" | jq '[.items[] | select(any(.metadata.ownerReferences[]?; .kind=="Rollout" and .name=="scout")) | select(.status.phase=="Successful") | select(any(.spec.args[]?; .name=="score" and .value=="95"))] | length')"
[ "$ok" -ge 1 ] || { echo "FAIL: no Successful AnalysisRun of scout with score=95 exists"; fail=1; }
first_ok="$(echo "$runs" | jq -r '[.items[] | select(.status.phase=="Successful") | .metadata.creationTimestamp] | min // ""')"
first_bad="$(echo "$runs" | jq -r '[.items[] | select(.status.phase=="Failed") | .metadata.creationTimestamp] | min // ""')"
if [ -n "$first_bad" ] && [ -n "$first_ok" ] && [[ "$first_ok" < "$first_bad" ]]; then
  echo "FAIL: the failed release must come before the successful one"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: version-3 passed its analysis and scout is Healthy"
exit "$fail"
