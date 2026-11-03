#!/usr/bin/env bash
# Lab starting state. Environment only: the repository with two commits on top
# of the first one (dev gets release-2, prod is set to 0 replicas) and two
# Applications that follow main.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$DIR/bootstrap/seed-repo.sh" fleet-config "$DIR/repo" public
kubectl apply -f "$DIR/manifests/applications.yaml"
for a in scout-dev scout-prod; do
  kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/$a --timeout=300s
  kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/$a --timeout=300s
done
PORT=$(( 30000 + RANDOM % 20000 ))
kubectl -n gitea port-forward svc/gitea-http "$PORT:3000" >/dev/null 2>&1 &
PF=$!
WORK="$(mktemp -d)"
trap 'kill $PF 2>/dev/null || true; rm -rf "$WORK"' EXIT
for i in $(seq 1 30); do curl -fs "http://127.0.0.1:$PORT/api/healthz" >/dev/null 2>&1 && break; sleep 1; done
git clone -q "http://platform:starfleet-gitops@127.0.0.1:$PORT/starfleet/fleet-config.git" "$WORK/repo"
cd "$WORK/repo"
G="git -c user.name=platform -c user.email=platform@starfleet.local"
sed -i.bak 's/value: release-1/value: release-2/' overlays/dev/kustomization.yaml
rm -f overlays/dev/kustomization.yaml.bak
$G commit -qam "dev: message release-2"
sed -i.bak 's/count: 2/count: 0/' overlays/prod/kustomization.yaml
rm -f overlays/prod/kustomization.yaml.bak
$G commit -qam "prod: set replicas to 0"
git push -q origin main
cd /
for a in scout-dev scout-prod; do
  kubectl -n argocd annotate application $a argocd.argoproj.io/refresh=hard --overwrite
done
for i in $(seq 1 60); do
  [ "$(kubectl -n scout-prod get deployment scout -o jsonpath='{.spec.replicas}' 2>/dev/null)" = "0" ] && break
  sleep 3
done
echo "[lab] Ready."
