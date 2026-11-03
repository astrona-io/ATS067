#!/usr/bin/env bash
# Check: scout is Healthy on version-3 with all pods ready and a Successful
# analysis run with score 95 exists.
set -uo pipefail
fail=0
r="$(kubectl -n starfleet get rollout scout -o json 2>/dev/null)" || { echo "FAIL: rollout scout not found"; exit 1; }
phase="$(echo "$r" | jq -r '.status.phase // ""')"
[ "$phase" = "Healthy" ] || { echo "FAIL: scout phase is '$phase', expected Healthy"; fail=1; }
msg="$(echo "$r" | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="PODINFO_UI_MESSAGE") | .value')"
[ "$msg" = "version-3" ] || { echo "FAIL: scout template message is '$msg', expected version-3"; fail=1; }
stable="$(echo "$r" | jq -r '.status.stableRS // ""')"; cur="$(echo "$r" | jq -r '.status.currentPodHash // ""')"
{ [ -n "$stable" ] && [ "$stable" = "$cur" ]; } || { echo "FAIL: stableRS '$stable' differs from currentPodHash '$cur'"; fail=1; }
ready="$(kubectl -n starfleet get pods -l app=scout -o json | jq '[.items[] | select(.metadata.deletionTimestamp == null) | select(any(.status.conditions[]?; .type=="Ready" and .status=="True")) | select(any(.spec.containers[0].env[]?; .name=="PODINFO_UI_MESSAGE" and .value=="version-3"))] | length')"
[ "$ready" = "4" ] || { echo "FAIL: $ready ready pods run version-3, expected 4"; fail=1; }
ok="$(kubectl -n starfleet get analysisrun -o json | jq '[.items[] | select(any(.metadata.ownerReferences[]?; .kind=="Rollout" and .name=="scout")) | select(.status.phase=="Successful") | select(any(.spec.args[]?; .name=="score" and .value=="95"))] | length')"
[ "$ok" -ge 1 ] || { echo "FAIL: no Successful AnalysisRun of scout with score=95 exists"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: scout is Healthy on version-3 after a successful analysis"
exit "$fail"
