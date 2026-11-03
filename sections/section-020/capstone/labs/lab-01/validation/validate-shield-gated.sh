#!/usr/bin/env bash
# Check: shield has a pre-promotion analysis, a release with score 40 failed it
# and the active Service still selects the stable ReplicaSet.
set -uo pipefail
fail=0
r="$(kubectl -n starfleet get rollout shield -o json 2>/dev/null)" || { echo "FAIL: rollout shield not found"; exit 1; }
t="$(echo "$r" | jq -r '[.spec.strategy.blueGreen.prePromotionAnalysis.templates[]?.templateName] | join(",")')"
case ",$t," in *,quality-gate,*) ;; *) echo "FAIL: strategy.blueGreen.prePromotionAnalysis must use quality-gate (found '$t')"; fail=1;; esac
bad="$(kubectl -n starfleet get analysisrun -o json | jq '[.items[] | select(any(.metadata.ownerReferences[]?; .kind=="Rollout" and .name=="shield")) | select(.status.phase=="Failed") | select(any(.spec.args[]?; .name=="score" and .value=="40"))] | length')"
[ "$bad" -ge 1 ] || { echo "FAIL: no Failed AnalysisRun of shield with score=40 exists"; fail=1; }
stable="$(echo "$r" | jq -r '.status.stableRS // ""')"; cur="$(echo "$r" | jq -r '.status.currentPodHash // ""')"
if [ -z "$stable" ] || [ "$stable" = "$cur" ]; then
  echo "FAIL: stableRS '$stable' must differ from currentPodHash '$cur' (the failed version must not be stable)"
  fail=1
fi
sel="$(kubectl -n starfleet get service shield -o jsonpath='{.spec.selector.rollouts-pod-template-hash}' 2>/dev/null)"
[ -n "$sel" ] && [ "$sel" = "$stable" ] || { echo "FAIL: the Service shield selects '$sel', stableRS is '$stable'"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the version with score 40 failed and shield still serves the stable version"
exit "$fail"
