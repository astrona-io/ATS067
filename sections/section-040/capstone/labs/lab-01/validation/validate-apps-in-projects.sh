#!/usr/bin/env bash
# Check: each Application is in its own project and has no InvalidSpecError.
set -uo pipefail
fail=0
for pair in scout-dev:dev-env scout-prod:prod-env; do
  app="${pair%%:*}"; proj="${pair##*:}"
  a="$(kubectl -n argocd get application "$app" -o json 2>/dev/null)" || { echo "FAIL: Application $app not found"; fail=1; continue; }
  [ "$(echo "$a" | jq -r '.spec.project')" = "$proj" ] || { echo "FAIL: $app is in project '$(echo "$a" | jq -r '.spec.project')', expected $proj"; fail=1; }
  [ "$(echo "$a" | jq -r '[.status.conditions[]? | select(.type=="InvalidSpecError")] | length')" = "0" ] || { echo "FAIL: $app has an InvalidSpecError condition"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "PASS: each Application is in its own project and accepted by it"
exit "$fail"
