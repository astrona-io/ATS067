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
sed -i.bak 's/value: version-1/value: version-2/' apps/scout/deployment.yaml
rm -f apps/scout/deployment.yaml.bak
git -c user.name=platform -c user.email=platform@starfleet.local commit -qam "scout: message version-2"
git push -q origin main
HEAD_SHA="$(git rev-parse HEAD)"
cd /
kubectl -n argocd annotate application scout argocd.argoproj.io/refresh=hard --overwrite
for i in $(seq 1 60); do
  [ "$(kubectl -n argocd get application scout -o jsonpath='{.status.sync.revision}')" = "$HEAD_SHA" ] && \
  [ "$(kubectl -n argocd get application scout -o jsonpath='{.status.sync.status}')" = "Synced" ] && break
  sleep 3
done

kubectl apply -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: ref-hook
  namespace: argo-events
spec:
  service:
    ports:
      - port: 12000
        targetPort: 12000
  webhook:
    release:
      port: "12000"
      endpoint: /release
      method: POST
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: ref-sensor
  namespace: argo-events
spec:
  template:
    serviceAccountName: sensor-runner
  dependencies:
    - name: release-dep
      eventSourceName: ref-hook
      eventName: release
  triggers:
    - template:
        name: set-state
        k8s:
          operation: patch
          source:
            resource:
              apiVersion: v1
              kind: ConfigMap
              metadata:
                name: deploy-state
                namespace: starfleet
              data:
                service: unset
                ref: unset
          parameters:
            - src:
                dependencyName: release-dep
                dataKey: body.service
              dest: data.service
            - src:
                dependencyName: release-dep
                dataKey: body.ref
              dest: data.ref
YAML
kubectl -n argo-events wait --for=condition=Ready pod -l eventsource-name=ref-hook --timeout=300s
kubectl -n argo-events wait --for=condition=Ready pod -l sensor-name=ref-sensor --timeout=300s
URL=http://ref-hook-eventsource-svc.argo-events.svc.cluster.local:12000/release
for i in 1 2; do
  kubectl -n starfleet exec deploy/shuttle -- curl -s -X POST "$URL" -H 'Content-Type: application/json' -d "{\"service\":\"scout\",\"ref\":\"$HEAD_SHA\"}"
  sleep 5
done
for i in $(seq 1 30); do
  [ "$(kubectl -n starfleet get configmap deploy-state -o jsonpath='{.data.ref}')" = "$HEAD_SHA" ] && break
  sleep 2
done
echo "[solution] Applied."
