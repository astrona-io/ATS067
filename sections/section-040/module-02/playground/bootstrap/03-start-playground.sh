#!/usr/bin/env bash
# Playground starting state: the repository with a Kustomize base and two
# overlays, and the Applications scout-dev and scout-prod.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$DIR/bootstrap/seed-repo.sh" fleet-config "$DIR/repo" public
kubectl apply -f "$DIR/manifests/applications.yaml"
for a in scout-dev scout-prod; do
  kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/$a --timeout=300s
  kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/$a --timeout=300s
done
echo "[playground] Ready."
