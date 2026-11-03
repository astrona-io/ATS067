#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
kubectl apply -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: crew
  namespace: argocd
spec:
  description: Applications of the crew team
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: starfleet
  clusterResourceWhitelist: []
YAML
for app in scout intruder; do
  kubectl -n argocd patch application "$app" --type merge -p '{"spec":{"project":"crew"}}'
  kubectl -n argocd annotate application "$app" argocd.argoproj.io/refresh=hard --overwrite
done
for i in $(seq 1 60); do
  n="$(kubectl -n argocd get application intruder -o json | jq '[.status.conditions[]? | select(.type=="InvalidSpecError")] | length')"
  [ "$n" != "0" ] && break
  sleep 3
done
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/scout --timeout=300s
echo "[solution] Applied."
