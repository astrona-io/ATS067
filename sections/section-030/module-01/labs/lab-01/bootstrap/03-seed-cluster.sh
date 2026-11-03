#!/usr/bin/env bash
# Lab starting state. Environment only: Git, the Application with automated
# sync only (no prune, no self-heal) and a synced Deployment and ConfigMap.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$DIR/bootstrap/seed-repo.sh" fleet-config "$DIR/repo" public
kubectl apply -f "$DIR/manifests/application.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/scout --timeout=300s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/scout --timeout=300s
echo "[lab] Ready."
