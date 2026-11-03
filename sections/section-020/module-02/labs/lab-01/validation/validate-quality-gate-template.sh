#!/usr/bin/env bash
# Check: the AnalysisTemplate quality-gate has the required web metric.
set -uo pipefail
fail=0
t="$(kubectl -n starfleet get analysistemplate quality-gate -o json 2>/dev/null)" || { echo "FAIL: AnalysisTemplate quality-gate not found in starfleet"; exit 1; }

echo "$t" | jq -e '[.spec.args[]?.name] | index("score") != null' >/dev/null || { echo "FAIL: the template must declare the argument score"; fail=1; }
m="$(echo "$t" | jq -c '.spec.metrics[]? | select(.name=="quality")')"
if [ -z "$m" ]; then
  echo "FAIL: the template needs a metric named quality"
  exit 1
fi
url="$(echo "$m" | jq -r '.provider.web.url // ""')"
case "$url" in
  http://httpbin.analysis.svc.cluster.local:8080/get\?score=*) ;;
  *) echo "FAIL: url must start with http://httpbin.analysis.svc.cluster.local:8080/get?score= (found '$url')"; fail=1;;
esac
echo "$url" | grep -q '{{ *args.score *}}' || { echo "FAIL: the url must pass the argument as {{ args.score }}"; fail=1; }
path="$(echo "$m" | jq -r '.provider.web.jsonPath // ""')"
[ "$path" = '{$.args.score[0]}' ] || { echo "FAIL: jsonPath must be {\$.args.score[0]} (found '$path')"; fail=1; }
cond="$(echo "$m" | jq -r '.successCondition // ""')"
[ "$cond" = 'asInt(result) >= 90' ] || { echo "FAIL: successCondition must be asInt(result) >= 90 (found '$cond')"; fail=1; }
interval="$(echo "$m" | jq -r '.interval // ""')"
count="$(echo "$m" | jq -r '.count // 0')"
limit="$(echo "$m" | jq -r '.failureLimit // 0')"
[ "$interval" = "10s" ] || { echo "FAIL: interval must be 10s (found '$interval')"; fail=1; }
[ "$count" = "3" ] || { echo "FAIL: count must be 3 (found $count)"; fail=1; }
[ "$limit" = "0" ] || { echo "FAIL: failureLimit must be 0 (found $limit)"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: quality-gate measures the score through the web provider"
exit "$fail"
