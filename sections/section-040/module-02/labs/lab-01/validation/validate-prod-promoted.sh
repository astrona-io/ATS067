#!/usr/bin/env bash
# Check: on main, prod has 2 replicas and release-2, dev is unchanged and the
# base was not edited.
set -uo pipefail
fail=0
REPO=/var/lib/gitea/git/repositories/starfleet/fleet-config.git
g() { kubectl -n gitea exec deploy/gitea -- git --git-dir="$REPO" "$@" 2>/dev/null; }
prod="$(g show main:overlays/prod/kustomization.yaml)"
dev="$(g show main:overlays/dev/kustomization.yaml)"
base="$(g show main:base/scout/deployment.yaml)"
[ -n "$prod" ] && [ -n "$dev" ] && [ -n "$base" ] || { echo "FAIL: cannot read the overlays and the base on main"; exit 1; }
echo "$prod" | grep -Eq '^[[:space:]]*count:[[:space:]]*2[[:space:]]*$' || { echo "FAIL: overlays/prod must set count 2"; fail=1; }
echo "$prod" | grep -Eq '^[[:space:]]*value:[[:space:]]*release-2[[:space:]]*$' || { echo "FAIL: overlays/prod must set the message release-2"; fail=1; }
echo "$dev" | grep -Eq '^[[:space:]]*count:[[:space:]]*1[[:space:]]*$' || { echo "FAIL: overlays/dev must keep count 1"; fail=1; }
echo "$dev" | grep -Eq '^[[:space:]]*value:[[:space:]]*release-2[[:space:]]*$' || { echo "FAIL: overlays/dev must keep the message release-2"; fail=1; }
echo "$base" | grep -Eq '^[[:space:]]*value:[[:space:]]*base[[:space:]]*$' || { echo "FAIL: base/scout/deployment.yaml must keep the message base (promote in the overlay only)"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: prod holds release-2 with 2 replicas and only the prod overlay changed"
exit "$fail"
