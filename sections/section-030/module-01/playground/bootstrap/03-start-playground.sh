#!/usr/bin/env bash
# Playground starting state: the repository starfleet/fleet-config in Gitea and
# the Application scout (automated sync without prune and self-heal).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$DIR/bootstrap/seed-repo.sh" fleet-config "$DIR/repo" public
kubectl apply -f "$DIR/manifests/application.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/scout --timeout=300s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/scout --timeout=300s
echo "[playground] Ready."
