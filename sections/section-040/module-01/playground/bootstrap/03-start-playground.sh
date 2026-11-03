#!/usr/bin/env bash
# Playground starting state: the repository, the project crew, a repository
# Secret and two Applications. scout is allowed by the project; outsider is not.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$DIR/bootstrap/seed-repo.sh" fleet-config "$DIR/repo" public
kubectl get namespace starfleet >/dev/null 2>&1 || kubectl create namespace starfleet
kubectl apply -f "$DIR/manifests/appproject.yaml"
kubectl apply -f "$DIR/manifests/repo-secret.yaml"
kubectl apply -f "$DIR/manifests/applications.yaml"
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/scout --timeout=300s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/scout --timeout=300s
echo "[playground] Ready."
