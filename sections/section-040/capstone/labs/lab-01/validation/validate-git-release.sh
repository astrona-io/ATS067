#!/usr/bin/env bash
# Check: the faulty prod commit is reverted (and still in history) and prod
# holds release-2 in the overlay. dev and base are unchanged.
set -uo pipefail
fail=0
REPO=/var/lib/gitea/git/repositories/starfleet/fleet-config.git
g() { kubectl -n gitea exec deploy/gitea -- git --git-dir="$REPO" "$@" 2>/dev/null; }
bad="$(g log main --format=%H --grep='^prod: bump podinfo to 6.99.0$' | tail -n 1)"
[ -n "$bad" ] || { echo "FAIL: the commit 'prod: bump podinfo to 6.99.0' is no longer in the history of main (do not rewrite history)"; exit 1; }
rev="$(g log main --format=%H --grep="This reverts commit $bad" | head -n 1)"
[ -n "$rev" ] || { echo "FAIL: no commit on main reverts $bad (use git revert)"; fail=1; }
prod="$(g show main:overlays/prod/kustomization.yaml)"
dev="$(g show main:overlays/dev/kustomization.yaml)"
base="$(g show main:base/scout/deployment.yaml)"
[ -n "$prod" ] && [ -n "$dev" ] && [ -n "$base" ] || { echo "FAIL: cannot read the overlays and the base on main"; exit 1; }
echo "$prod" | grep -Eq '^[[:space:]]*value:[[:space:]]*release-2[[:space:]]*$' || { echo "FAIL: overlays/prod must set the message release-2"; fail=1; }
echo "$prod" | grep -q '6.99.0' && { echo "FAIL: overlays/prod still holds the image tag 6.99.0"; fail=1; }
echo "$dev" | grep -Eq '^[[:space:]]*value:[[:space:]]*release-2[[:space:]]*$' || { echo "FAIL: overlays/dev must keep the message release-2"; fail=1; }
echo "$base" | grep -Eq '^[[:space:]]*value:[[:space:]]*base[[:space:]]*$' || { echo "FAIL: base/scout/deployment.yaml must keep the message base"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the faulty commit is reverted and prod holds release-2 in its overlay"
exit "$fail"
