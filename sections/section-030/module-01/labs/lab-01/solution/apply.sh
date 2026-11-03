#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
kubectl -n argocd patch application scout --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'

PORT=$(( 30000 + RANDOM % 20000 ))
kubectl -n gitea port-forward svc/gitea-http "$PORT:3000" >/dev/null 2>&1 &
PF=$!
WORK="$(mktemp -d)"
trap 'kill $PF 2>/dev/null || true; rm -rf "$WORK"' EXIT
for i in $(seq 1 30); do curl -fs "http://127.0.0.1:$PORT/api/healthz" >/dev/null 2>&1 && break; sleep 1; done
git clone -q "http://platform:starfleet-gitops@127.0.0.1:$PORT/starfleet/fleet-config.git" "$WORK/repo"
cd "$WORK/repo"
sed -i.bak 's/replicas: 2/replicas: 3/' apps/scout/deployment.yaml
rm -f apps/scout/deployment.yaml.bak apps/scout/old-flags.yaml
git -c user.name=platform -c user.email=platform@starfleet.local commit -qam "scout: 3 replicas, remove old flags"
git push -q origin main
cd /
kubectl -n argocd annotate application scout argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/scout --timeout=300s
kubectl -n starfleet wait --for=jsonpath='{.status.readyReplicas}'=3 deployment/scout --timeout=300s
for i in $(seq 1 60); do
  [ "$(kubectl -n argocd get application scout -o jsonpath='{.status.sync.revision}')" = "$(git -C "$WORK/repo" rev-parse HEAD)" ] && break
  sleep 3
done
kubectl -n starfleet create configmap sync-record \
  --from-literal=synced-revision="$(kubectl -n argocd get application scout -o jsonpath='{.status.sync.revision}')" \
  --from-literal=replicas="$(kubectl -n starfleet get deployment scout -o jsonpath='{.spec.replicas}')" \
  --from-literal=observed-at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "[solution] Applied."
