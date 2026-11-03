#!/usr/bin/env bash
# Guard: Gitea, Argo CD, both Applications and both Deployments exist.
set -uo pipefail
fail=0
kubectl -n gitea get deployment gitea >/dev/null 2>&1 || { echo "FAIL: deployment gitea is missing"; fail=1; }
kubectl -n argocd get statefulset argocd-application-controller >/dev/null 2>&1 || { echo "FAIL: the Argo CD application controller is missing"; fail=1; }
for a in scout-dev scout-prod; do
  kubectl -n argocd get application $a >/dev/null 2>&1 || { echo "FAIL: Application $a is missing"; fail=1; }
done
kubectl -n scout-dev get deployment scout >/dev/null 2>&1 || { echo "FAIL: deployment scout is missing in scout-dev"; fail=1; }
kubectl -n scout-prod get deployment scout >/dev/null 2>&1 || { echo "FAIL: deployment scout is missing in scout-prod"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: Gitea, Argo CD, both Applications and the Deployments exist"
exit "$fail"
