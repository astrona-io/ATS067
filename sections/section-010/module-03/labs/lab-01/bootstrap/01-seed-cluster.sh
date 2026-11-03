#!/usr/bin/env bash
# Starting state for the recreate and feature flag lab. Environment only.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in ledger flagcheck shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
echo "[lab] Ready."
