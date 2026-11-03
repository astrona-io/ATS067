#!/usr/bin/env bash
# Check: dev-env and prod-env each allow one repository, one namespace and no
# cluster-scoped kinds.
set -uo pipefail
fail=0
URL=http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git
for pair in dev-env:scout-dev prod-env:scout-prod; do
  proj="${pair%%:*}"; ns="${pair##*:}"
  p="$(kubectl -n argocd get appproject "$proj" -o json 2>/dev/null)" || { echo "FAIL: AppProject $proj not found in argocd"; fail=1; continue; }
  echo "$p" | jq -e --arg u "$URL" '(.spec.sourceRepos // []) == [$u]' >/dev/null || { echo "FAIL: $proj sourceRepos must list exactly $URL"; fail=1; }
  if ! echo "$p" | jq -e '(.spec.destinations // []) | length == 1' >/dev/null; then
    echo "FAIL: $proj destinations must hold exactly one entry"; fail=1
  else
    echo "$p" | jq -e --arg ns "$ns" '.spec.destinations[0].namespace == $ns' >/dev/null || { echo "FAIL: the destination namespace of $proj must be $ns"; fail=1; }
    echo "$p" | jq -e '.spec.destinations[0] | (.server == "https://kubernetes.default.svc") or (.name == "in-cluster")' >/dev/null || { echo "FAIL: the destination of $proj must be the in-cluster server"; fail=1; }
  fi
  echo "$p" | jq -e '(.spec.clusterResourceWhitelist // []) | length == 0' >/dev/null || { echo "FAIL: $proj clusterResourceWhitelist must be empty"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "PASS: both projects allow one repository, one namespace and no cluster-scoped kinds"
exit "$fail"
