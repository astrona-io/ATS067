#!/usr/bin/env bash
# Check: an analysis with score 40 failed for scout. The failed release did not
# become stable: this is proven by the Failed run and by the final good state.
set -uo pipefail
fail=0
runs="$(kubectl -n starfleet get analysisrun -o json 2>/dev/null)" || { echo "FAIL: cannot read AnalysisRuns"; exit 1; }
failed="$(echo "$runs" | jq '[.items[] | select(any(.metadata.ownerReferences[]?; .kind=="Rollout" and .name=="scout")) | select(.status.phase=="Failed") | select(any(.spec.args[]?; .name=="score" and .value=="40"))] | length')"
if [ "$failed" -lt 1 ]; then
  echo "FAIL: no Failed AnalysisRun of scout with the argument score=40 exists"
  fail=1
fi
r="$(kubectl -n starfleet get rollout scout -o json 2>/dev/null)" || exit 1
bad="$(echo "$r" | jq -r '.spec.strategy.canary.analysis.templates[]?.templateName' | grep -c '^quality-gate$' || true)"
if [ "$bad" -lt 1 ]; then
  echo "FAIL: the Rollout scout must use the template quality-gate in strategy.canary.analysis"
  fail=1
fi
running_bad="$(kubectl -n starfleet get pods -l app=scout -o json | jq '[.items[] | select(.metadata.deletionTimestamp == null) | select(any(.spec.containers[0].env[]?; .name=="PODINFO_UI_MESSAGE" and .value=="version-bad"))] | length')"
if [ "$running_bad" != "0" ]; then
  echo "FAIL: $running_bad pods still run version-bad"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: the release with score 40 failed its analysis and no version-bad pod runs"
exit "$fail"
