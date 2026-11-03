#!/usr/bin/env bash
# Playground starting state: go-httpbin, the template quality-gate and the Rollout scout at version 1.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$DIR/manifests/starfleet.yaml"
kubectl -n analysis rollout status deployment/httpbin --timeout=180s
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Healthy rollout/scout --timeout=240s
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
echo "[playground] Ready."
