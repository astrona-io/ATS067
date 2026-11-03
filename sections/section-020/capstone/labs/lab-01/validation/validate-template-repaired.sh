#!/usr/bin/env bash
# Check: the AnalysisTemplate quality-gate keeps its metric and its threshold
# lets a score of 95 pass while a score of 40 still fails.
set -uo pipefail
fail=0
t="$(kubectl -n starfleet get analysistemplate quality-gate -o json 2>/dev/null)" || { echo "FAIL: AnalysisTemplate quality-gate not found in starfleet"; exit 1; }
m="$(echo "$t" | jq -c '.spec.metrics[]? | select(.name=="quality")')"
[ -n "$m" ] || { echo "FAIL: the metric quality is missing"; exit 1; }
cond="$(echo "$m" | jq -r '.successCondition // ""')"
if [[ "$cond" =~ asInt\(result\)[[:space:]]*\>=[[:space:]]*([0-9]+) ]]; then
  limit="${BASH_REMATCH[1]}"
  if [ "$limit" -gt 95 ] || [ "$limit" -le 40 ]; then
    echo "FAIL: the threshold is $limit; it must be above 40 and not above 95"
    fail=1
  fi
else
  echo "FAIL: successCondition must compare asInt(result) with >= and a number (found '$cond')"
  fail=1
fi
url="$(echo "$m" | jq -r '.provider.web.url // ""')"
case "$url" in *"httpbin.analysis.svc.cluster.local:8080/get?score={{ args.score }}"*) ;; *) echo "FAIL: the URL must still call go-httpbin with the argument score (found '$url')"; fail=1;; esac
[ "$(echo "$m" | jq -r '.provider.web.jsonPath // ""')" = '{$.args.score[0]}' ] || { echo "FAIL: jsonPath must be {\$.args.score[0]}"; fail=1; }
[ "$(echo "$m" | jq -r '.failureLimit // 0')" = "0" ] || { echo "FAIL: failureLimit must stay 0"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the template passes a score of 95 and fails a score of 40"
exit "$fail"
