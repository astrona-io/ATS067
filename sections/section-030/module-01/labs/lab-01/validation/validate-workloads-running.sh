#!/usr/bin/env bash
# Guard: Gitea, Argo CD and the Application scout still exist.
set -uo pipefail
fail=0
kubectl -n gitea get deployment gitea >/dev/null 2>&1 || { echo "FAIL: deployment gitea is missing"; fail=1; }
kubectl -n argocd get statefulset argocd-application-controller >/dev/null 2>&1 || { echo "FAIL: argocd-application-controller is missing"; fail=1; }
kubectl -n argocd get application scout >/dev/null 2>&1 || { echo "FAIL: Application scout is missing"; fail=1; }
kubectl -n starfleet get deployment scout >/dev/null 2>&1 || { echo "FAIL: deployment scout is missing in starfleet"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: Gitea, Argo CD, the Application and the Deployment exist"
exit "$fail"
