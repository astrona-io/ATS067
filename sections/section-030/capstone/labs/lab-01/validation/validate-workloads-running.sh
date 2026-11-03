#!/usr/bin/env bash
# Guard: Gitea, Argo CD, Argo Events, the client and the target ConfigMap exist.
set -uo pipefail
fail=0
kubectl -n gitea get deployment gitea >/dev/null 2>&1 || { echo "FAIL: deployment gitea is missing"; fail=1; }
kubectl -n argocd get application scout >/dev/null 2>&1 || { echo "FAIL: Application scout is missing"; fail=1; }
kubectl -n argo-events get eventbus default >/dev/null 2>&1 || { echo "FAIL: EventBus default is missing"; fail=1; }
kubectl -n starfleet get deployment scout >/dev/null 2>&1 || { echo "FAIL: deployment scout is missing in starfleet"; fail=1; }
kubectl -n starfleet get deployment shuttle >/dev/null 2>&1 || { echo "FAIL: deployment shuttle is missing"; fail=1; }
kubectl -n starfleet get configmap deploy-state >/dev/null 2>&1 || { echo "FAIL: ConfigMap deploy-state is missing"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: Gitea, Argo CD, Argo Events, the client and deploy-state exist"
exit "$fail"
