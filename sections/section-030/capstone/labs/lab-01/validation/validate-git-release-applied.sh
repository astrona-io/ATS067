#!/usr/bin/env bash
# Check: main sets the message version-2 and the cluster is reconciled to the
# head of main.
set -uo pipefail
fail=0
REPO=/var/lib/gitea/git/repositories/starfleet/fleet-config.git
g() { kubectl -n gitea exec deploy/gitea -- git --git-dir="$REPO" "$@" 2>/dev/null; }
head="$(g rev-parse main)"
[ -n "$head" ] || { echo "FAIL: cannot read the branch main of starfleet/fleet-config"; exit 1; }
g show main:apps/scout/deployment.yaml | grep -Eq '^[[:space:]]*value:[[:space:]]*version-2[[:space:]]*$' || { echo "FAIL: apps/scout/deployment.yaml on main must set PODINFO_UI_MESSAGE to version-2"; fail=1; }
a="$(kubectl -n argocd get application scout -o json)" || exit 1
[ "$(echo "$a" | jq -r '.status.sync.status')" = "Synced" ] || { echo "FAIL: the Application is not Synced"; fail=1; }
[ "$(echo "$a" | jq -r '.status.sync.revision')" = "$head" ] || { echo "FAIL: the Application revision is not the head of main ($head)"; fail=1; }
msg="$(kubectl -n starfleet get deployment scout -o json | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="PODINFO_UI_MESSAGE") | .value')"
[ "$msg" = "version-2" ] || { echo "FAIL: the live Deployment has the message '$msg', expected version-2"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the commit with version-2 is reconciled"
exit "$fail"
