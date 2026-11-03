#!/usr/bin/env bash
# Check: both Applications are Synced and Healthy at the head of main and the
# live Deployments show release-2 with the original image.
set -uo pipefail
fail=0
REPO=/var/lib/gitea/git/repositories/starfleet/fleet-config.git
head="$(kubectl -n gitea exec deploy/gitea -- git --git-dir="$REPO" rev-parse main 2>/dev/null)"
[ -n "$head" ] || { echo "FAIL: cannot read the branch main of starfleet/fleet-config"; exit 1; }
for env in dev prod; do
  a="$(kubectl -n argocd get application scout-$env -o json 2>/dev/null)" || { echo "FAIL: Application scout-$env not found"; fail=1; continue; }
  [ "$(echo "$a" | jq -r '.status.sync.status')" = "Synced" ] || { echo "FAIL: scout-$env is not Synced"; fail=1; }
  [ "$(echo "$a" | jq -r '.status.health.status')" = "Healthy" ] || { echo "FAIL: scout-$env is not Healthy"; fail=1; }
  [ "$(echo "$a" | jq -r '.status.sync.revision')" = "$head" ] || { echo "FAIL: scout-$env is not at the head of main ($head)"; fail=1; }
  d="$(kubectl -n scout-$env get deployment scout -o json 2>/dev/null)" || { echo "FAIL: deployment scout missing in scout-$env"; fail=1; continue; }
  [ "$(echo "$d" | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="PODINFO_UI_MESSAGE") | .value')" = "release-2" ] || { echo "FAIL: scout-$env does not run the message release-2"; fail=1; }
  echo "$d" | jq -r '.spec.template.spec.containers[0].image' | grep -q '6.15.0' || { echo "FAIL: scout-$env does not run the image 6.15.0"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "PASS: both environments are reconciled to the head of main"
exit "$fail"
