#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# warp: fix the readiness probe path and the rolling update settings.
kubectl -n starfleet patch deployment warp --patch-file "$DIR/warp-fix.yaml"
kubectl -n starfleet rollout status deployment/warp --timeout=240s

# impulse: go back to the last good revision.
kubectl -n starfleet rollout undo deployment/impulse
kubectl -n starfleet rollout status deployment/impulse --timeout=240s

warp_revision="$(kubectl -n starfleet get deployment warp -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')"
impulse_revision="$(kubectl -n starfleet get deployment impulse -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')"
kubectl -n starfleet patch service shield --type merge -p '{"spec":{"selector":{"track":"green"}}}'

observed="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl -n starfleet create configmap release-record \
  --from-literal=warp-revision="$warp_revision" \
  --from-literal=impulse-revision="$impulse_revision" \
  --from-literal=shield-track=green \
  --from-literal=observed-at="$observed"
echo "[solution] Applied."
