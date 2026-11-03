#!/usr/bin/env bash
# Guard: Gitea, Argo CD and both Applications exist, and the workload runs.
set -uo pipefail
fail=0
kubectl -n gitea get deployment gitea >/dev/null 2>&1 || { echo "FAIL: deployment gitea is missing"; fail=1; }
kubectl -n argocd get statefulset argocd-application-controller >/dev/null 2>&1 || { echo "FAIL: the Argo CD application controller is missing"; fail=1; }
kubectl -n argocd get application scout >/dev/null 2>&1 || { echo "FAIL: Application scout is missing"; fail=1; }
kubectl -n argocd get application intruder >/dev/null 2>&1 || { echo "FAIL: Application intruder is missing (do not delete it)"; fail=1; }
kubectl -n starfleet get deployment scout >/dev/null 2>&1 || { echo "FAIL: deployment scout is missing in starfleet"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: Gitea, Argo CD, both Applications and the workload exist"
exit "$fail"
