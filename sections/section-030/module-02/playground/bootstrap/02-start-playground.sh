#!/usr/bin/env bash
# Playground starting state: a webhook EventSource, a Sensor with a create
# trigger, the client and the permissions of the sensor.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for i in $(seq 1 60); do kubectl -n argo-events get statefulset eventbus-default-js >/dev/null 2>&1 && break; sleep 3; done
kubectl -n argo-events rollout status statefulset/eventbus-default-js --timeout=300s
kubectl apply -f "$DIR/manifests/starfleet.yaml"
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
kubectl -n argo-events wait --for=condition=Ready pod -l eventsource-name=fleet-hook --timeout=300s
kubectl -n argo-events wait --for=condition=Ready pod -l sensor-name=fleet-sensor --timeout=300s
echo "[playground] Ready."
