#!/usr/bin/env bash
# Starting state for the rolling update lab. Environment only: it creates the
# healthy revision 1 of scout and probe, then starts the two faulty updates.
# It does not wait for the faulty updates to finish, because they never do.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done

# Faulty update 1: wrong readiness probe path for scout.
kubectl apply -f "$DIR/manifests/scout-update.yaml"
# Faulty update 2: an image tag that does not exist for probe.
kubectl -n starfleet set image deployment/probe probe=ghcr.io/stefanprodan/podinfo:6.15.0-broken
echo "[lab] Ready."
