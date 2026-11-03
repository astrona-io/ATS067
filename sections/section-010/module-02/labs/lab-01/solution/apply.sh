#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

# scout: send the traffic to green. A merge patch on spec.selector sets track.
kubectl -n starfleet patch service scout --type merge -p '{"spec":{"selector":{"track":"green"}}}'

# probe: remove the track label from the selector and add one canary pod.
kubectl -n starfleet patch service probe --type json -p '[{"op":"remove","path":"/spec/selector/track"}]'
kubectl -n starfleet scale deployment/probe-canary --replicas=1
kubectl -n starfleet rollout status deployment/probe-canary --timeout=240s

# Wait until the endpoints reflect the change.
for _ in $(seq 1 30); do
  n="$(kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=probe -o json | jq '[.items[].endpoints[]? | select(.conditions.ready == true)] | length')"
  [ "$n" = "4" ] && break
  sleep 2
done

observed="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl -n starfleet create configmap release-evidence \
  --from-literal=active-track=green \
  --from-literal=canary-percent=25 \
  --from-literal=observed-at="$observed"
echo "[solution] Applied."
