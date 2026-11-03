#!/usr/bin/env bash
# Guard: the controller, the EventBus, the client and the target ConfigMap exist.
set -uo pipefail
fail=0
kubectl -n argo-events get deployment controller-manager >/dev/null 2>&1 || { echo "FAIL: controller-manager is missing"; fail=1; }
kubectl -n argo-events get eventbus default >/dev/null 2>&1 || { echo "FAIL: EventBus default is missing"; fail=1; }
kubectl -n starfleet get deployment shuttle >/dev/null 2>&1 || { echo "FAIL: deployment shuttle is missing"; fail=1; }
kubectl -n starfleet get configmap deploy-state >/dev/null 2>&1 || { echo "FAIL: ConfigMap deploy-state is missing"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the controller, the EventBus, the client and deploy-state exist"
exit "$fail"
