#!/usr/bin/env bash
# Check: the AppProject crew allows one repository, one destination and no
# cluster-scoped kinds.
set -uo pipefail
fail=0
p="$(kubectl -n argocd get appproject crew -o json 2>/dev/null)" || { echo "FAIL: AppProject crew not found in argocd"; exit 1; }
URL=http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git
echo "$p" | jq -e --arg u "$URL" '(.spec.sourceRepos // []) == [$u]' >/dev/null || { echo "FAIL: sourceRepos must list exactly $URL"; fail=1; }
if ! echo "$p" | jq -e '(.spec.destinations // []) | length == 1' >/dev/null; then
  echo "FAIL: destinations must hold exactly one entry"; fail=1
else
  echo "$p" | jq -e '.spec.destinations[0].namespace == "starfleet"' >/dev/null || { echo "FAIL: the destination namespace must be starfleet"; fail=1; }
  echo "$p" | jq -e '.spec.destinations[0] | (.server == "https://kubernetes.default.svc") or (.name == "in-cluster")' >/dev/null || { echo "FAIL: the destination must be the in-cluster server https://kubernetes.default.svc"; fail=1; }
fi
echo "$p" | jq -e '(.spec.clusterResourceWhitelist // []) | length == 0' >/dev/null || { echo "FAIL: clusterResourceWhitelist must be empty (no cluster-scoped kinds)"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: crew allows one repository, one destination and no cluster-scoped kinds"
exit "$fail"
