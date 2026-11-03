#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# scout: fix the readiness probe path and the rolling update settings.
kubectl -n starfleet patch deployment scout --patch-file "$DIR/scout-fix.yaml"
kubectl -n starfleet rollout status deployment/scout --timeout=240s

# probe: go back to the last good revision.
kubectl -n starfleet rollout undo deployment/probe
kubectl -n starfleet rollout status deployment/probe --timeout=240s

scout_revision="$(kubectl -n starfleet get deployment scout -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')"
probe_revision="$(kubectl -n starfleet get deployment probe -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')"
observed="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl -n starfleet create configmap release-record \
  --from-literal=scout-revision="$scout_revision" \
  --from-literal=probe-revision="$probe_revision" \
  --from-literal=observed-at="$observed"
echo "[solution] Applied."
