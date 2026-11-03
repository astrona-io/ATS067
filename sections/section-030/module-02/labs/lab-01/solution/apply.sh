#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
kubectl apply -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: fleet-hook
  namespace: argo-events
spec:
  service:
    ports:
      - port: 12000
        targetPort: 12000
  webhook:
    deploy:
      port: "12000"
      endpoint: /deploy
      method: POST
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: fleet-sensor
  namespace: argo-events
spec:
  template:
    serviceAccountName: sensor-runner
  dependencies:
    - name: deploy-dep
      eventSourceName: fleet-hook
      eventName: deploy
      filters:
        data:
          - path: body.ref
            type: string
            value:
              - main
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
                dependencyName: deploy-dep
                dataKey: body.service
              dest: data.service
            - src:
                dependencyName: deploy-dep
                dataKey: body.ref
              dest: data.ref
YAML
kubectl -n argo-events wait --for=condition=Ready pod -l eventsource-name=fleet-hook --timeout=300s
kubectl -n argo-events wait --for=condition=Ready pod -l sensor-name=fleet-sensor --timeout=300s
URL=http://fleet-hook-eventsource-svc.argo-events.svc.cluster.local:12000/deploy
send() { kubectl -n starfleet exec deploy/shuttle -- curl -s -X POST "$URL" -H 'Content-Type: application/json' -d "$1"; }
# A filtered-out event first, then the real event twice.
send '{"service":"hull","ref":"dev"}'
for i in 1 2; do send '{"service":"scout","ref":"main"}'; sleep 5; done
for i in $(seq 1 30); do
  [ "$(kubectl -n starfleet get configmap deploy-state -o jsonpath='{.data.ref}')" = "main" ] && break
  sleep 2
done
echo "[solution] Applied."
