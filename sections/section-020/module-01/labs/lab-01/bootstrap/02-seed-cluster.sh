#!/usr/bin/env bash
# Lab starting state. Environment only.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$DIR/manifests/lab-start.yaml"
for r in scout shield; do
  kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Healthy "rollout/$r" --timeout=240s
done
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
echo "[lab] Ready."
