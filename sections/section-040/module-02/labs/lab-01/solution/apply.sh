#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
PORT=$(( 30000 + RANDOM % 20000 ))
kubectl -n gitea port-forward svc/gitea-http "$PORT:3000" >/dev/null 2>&1 &
PF=$!
WORK="$(mktemp -d)"
trap 'kill $PF 2>/dev/null || true; rm -rf "$WORK"' EXIT
for i in $(seq 1 30); do curl -fs "http://127.0.0.1:$PORT/api/healthz" >/dev/null 2>&1 && break; sleep 1; done
git clone -q "http://platform:starfleet-gitops@127.0.0.1:$PORT/starfleet/fleet-config.git" "$WORK/repo"
cd "$WORK/repo"
G="git -c user.name=platform -c user.email=platform@starfleet.local"
BAD="$(git log --format=%H --grep='^prod: set replicas to 0$' -n 1)"
$G revert --no-edit "$BAD"
sed -i.bak 's/value: release-1/value: release-2/' overlays/prod/kustomization.yaml
rm -f overlays/prod/kustomization.yaml.bak
$G commit -qam "prod: message release-2"
git push -q origin main
HEAD_SHA="$(git rev-parse HEAD)"
cd /
for a in scout-dev scout-prod; do
  kubectl -n argocd annotate application $a argocd.argoproj.io/refresh=hard --overwrite
done
for i in $(seq 1 60); do
  [ "$(kubectl -n argocd get application scout-prod -o jsonpath='{.status.sync.revision}')" = "$HEAD_SHA" ] && \
  [ "$(kubectl -n argocd get application scout-dev -o jsonpath='{.status.sync.revision}')" = "$HEAD_SHA" ] && break
  sleep 3
done
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/scout-prod --timeout=300s
echo "[solution] Applied."
