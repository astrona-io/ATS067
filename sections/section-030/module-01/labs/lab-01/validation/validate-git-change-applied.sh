#!/usr/bin/env bash
# Check: the head of main holds replicas 3 and no old-flags.yaml, and the
# cluster was reconciled to exactly that commit.
set -uo pipefail
fail=0
REPO=/var/lib/gitea/git/repositories/starfleet/fleet-config.git
g() { kubectl -n gitea exec deploy/gitea -- git --git-dir="$REPO" "$@" 2>/dev/null; }
head="$(g rev-parse main)"
[ -n "$head" ] || { echo "FAIL: cannot read the branch main of starfleet/fleet-config"; exit 1; }
g show main:apps/scout/deployment.yaml | grep -Eq '^[[:space:]]*replicas:[[:space:]]*3[[:space:]]*$' || { echo "FAIL: apps/scout/deployment.yaml on main must set replicas: 3"; fail=1; }
if g cat-file -e main:apps/scout/old-flags.yaml; then echo "FAIL: apps/scout/old-flags.yaml still exists on main"; fail=1; fi
a="$(kubectl -n argocd get application scout -o json)" || exit 1
[ "$(echo "$a" | jq -r '.status.sync.status')" = "Synced" ] || { echo "FAIL: the Application is not Synced"; fail=1; }
[ "$(echo "$a" | jq -r '.status.sync.revision')" = "$head" ] || { echo "FAIL: the Application revision is not the head of main ($head)"; fail=1; }
live="$(kubectl -n starfleet get deployment scout -o jsonpath='{.spec.replicas}')"
[ "$live" = "3" ] || { echo "FAIL: the live Deployment has $live replicas, expected 3"; fail=1; }
if kubectl -n starfleet get configmap old-flags >/dev/null 2>&1; then echo "FAIL: ConfigMap old-flags still exists in the cluster (was it pruned?)"; fail=1; fi
[ "$fail" -eq 0 ] && echo "PASS: the commit on main is reconciled: 3 replicas and old-flags pruned"
exit "$fail"
