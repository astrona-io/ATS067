#!/usr/bin/env bash
# Lab starting state. Environment only.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n analysis rollout status deployment/httpbin --timeout=180s
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Healthy rollout/scout --timeout=240s
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
echo "[lab] Ready."
