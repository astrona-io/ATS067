#!/usr/bin/env bash
# Lab starting state. Environment only: Git, an Application with manual sync
# that was synced once, a live change that Git does not have (6 replicas), the
# ready EventBus, the client, the permissions and deploy-state.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$DIR/bootstrap/seed-repo.sh" fleet-config "$DIR/repo" public
kubectl apply -f "$DIR/manifests/application.yaml"
kubectl -n argocd patch application scout --type merge -p '{"operation":{"sync":{"revision":"main"}}}'
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/scout --timeout=300s
for i in $(seq 1 60); do kubectl -n argo-events get statefulset eventbus-default-js >/dev/null 2>&1 && break; sleep 3; done
kubectl -n argo-events rollout status statefulset/eventbus-default-js --timeout=300s
kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
kubectl -n starfleet rollout status deployment/scout --timeout=300s
kubectl -n starfleet scale deployment scout --replicas=6
echo "[lab] Ready."
