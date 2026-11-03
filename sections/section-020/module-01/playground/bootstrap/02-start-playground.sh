#!/usr/bin/env bash
# Playground starting state: the Rollouts scout and shield at version 1.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$DIR/manifests/starfleet.yaml"
for r in scout shield; do
  kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Healthy "rollout/$r" --timeout=240s
done
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
echo "[playground] Ready."
