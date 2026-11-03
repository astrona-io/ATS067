#!/usr/bin/env bash
# Starting state for the blue-green and canary lab. Environment only.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in scout-blue scout-green probe-stable shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
echo "[lab] Ready."
