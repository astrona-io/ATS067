#!/usr/bin/env bash
# Check: the faulty prod commit is still in the history of main and a revert
# commit for it exists (history was not rewritten).
set -uo pipefail
fail=0
REPO=/var/lib/gitea/git/repositories/starfleet/fleet-config.git
g() { kubectl -n gitea exec deploy/gitea -- git --git-dir="$REPO" "$@" 2>/dev/null; }
bad="$(g log main --format=%H --grep='^prod: set replicas to 0$' | tail -n 1)"
[ -n "$bad" ] || { echo "FAIL: the commit 'prod: set replicas to 0' is no longer in the history of main (do not rewrite history)"; exit 1; }
rev="$(g log main --format=%H --grep="This reverts commit $bad" | head -n 1)"
[ -n "$rev" ] || { echo "FAIL: no commit on main reverts $bad (use git revert)"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the faulty commit is reverted and still in the history"
exit "$fail"
