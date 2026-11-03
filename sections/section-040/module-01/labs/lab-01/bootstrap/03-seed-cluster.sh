#!/usr/bin/env bash
# Lab starting state. Environment only: the repository and two Applications in
# the project default. scout deploys to starfleet and intruder deploys to vault.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$DIR/bootstrap/seed-repo.sh" fleet-config "$DIR/repo" public
kubectl apply -f "$DIR/manifests/applications.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/scout --timeout=300s
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/intruder --timeout=300s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/scout --timeout=300s
echo "[lab] Ready."
