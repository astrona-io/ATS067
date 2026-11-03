#!/usr/bin/env bash
# Lab starting state. Environment only: the bus is ready, the client, the
# permissions and the ConfigMap deploy-state exist. No EventSource, no Sensor.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for i in $(seq 1 60); do kubectl -n argo-events get statefulset eventbus-default-js >/dev/null 2>&1 && break; sleep 3; done
kubectl -n argo-events rollout status statefulset/eventbus-default-js --timeout=300s
kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
echo "[lab] Ready."
