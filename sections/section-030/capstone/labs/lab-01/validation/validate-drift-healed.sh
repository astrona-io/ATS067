#!/usr/bin/env bash
# Check: automated sync with self-heal and prune is on, and the live
# replica count equals the value in Git (the manual change was reverted).
set -uo pipefail
fail=0
a="$(kubectl -n argocd get application scout -o json 2>/dev/null)" || { echo "FAIL: Application scout not found"; exit 1; }
[ "$(echo "$a" | jq -r '.spec.syncPolicy.automated.selfHeal // false')" = "true" ] || { echo "FAIL: automated.selfHeal must be true"; fail=1; }
[ "$(echo "$a" | jq -r '.spec.syncPolicy.automated.prune // false')" = "true" ] || { echo "FAIL: automated.prune must be true"; fail=1; }
REPO=/var/lib/gitea/git/repositories/starfleet/fleet-config.git
want="$(kubectl -n gitea exec deploy/gitea -- git --git-dir="$REPO" show main:apps/scout/deployment.yaml 2>/dev/null | sed -n 's/^[[:space:]]*replicas:[[:space:]]*\([0-9]*\).*/\1/p' | head -n 1)"
live="$(kubectl -n starfleet get deployment scout -o jsonpath='{.spec.replicas}')"
if [ -z "$want" ] || [ "$live" != "$want" ]; then
  echo "FAIL: the live Deployment has $live replicas, Git has '$want'"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: self-heal is on and the live replicas equal Git ($want)"
exit "$fail"
