#!/usr/bin/env bash
# Lab starting state. Environment only: the template has a condition that no
# normal score meets, and the blue-green Rollout has no analysis.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n analysis rollout status deployment/httpbin --timeout=180s
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Healthy rollout/scout --timeout=240s
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Healthy rollout/shield --timeout=240s
kubectl -n starfleet rollout status deployment/shuttle --timeout=120s
echo "[lab] Ready."
