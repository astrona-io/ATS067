#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail
NS=starfleet

# scout: gradual steps and the new template in one change.
kubectl -n $NS patch rollout scout --type json -p '[
 {"op":"replace","path":"/spec/strategy/canary/steps","value":[{"setWeight":25},{"pause":{"duration":"15s"}},{"setWeight":50},{"pause":{"duration":"15s"}}]},
 {"op":"replace","path":"/spec/template/spec/containers/0/image","value":"ghcr.io/stefanprodan/podinfo:6.14.0"},
 {"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-2"}]'
kubectl -n $NS wait --for=jsonpath='{.status.phase}'=Healthy rollout/scout --timeout=400s

# shield: stage the release in preview and wait for a promotion that never comes.
kubectl -n $NS patch rollout shield --type json -p '[
 {"op":"add","path":"/spec/strategy/blueGreen/autoPromotionEnabled","value":false},
 {"op":"add","path":"/spec/strategy/blueGreen/previewReplicaCount","value":1},
 {"op":"replace","path":"/spec/template/spec/containers/0/image","value":"ghcr.io/stefanprodan/podinfo:6.14.0"},
 {"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-2"}]'
kubectl -n $NS wait --for=jsonpath='{.status.phase}'=Paused rollout/shield --timeout=240s

stable="$(kubectl -n $NS get rollout scout -o jsonpath='{.status.stableRS}')"
active="$(kubectl -n $NS get service shield-active -o jsonpath='{.spec.selector.rollouts-pod-template-hash}')"
observed="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl -n $NS create configmap rollout-record \
  --from-literal=scout-stable-rs="$stable" \
  --from-literal=shield-active-hash="$active" \
  --from-literal=observed-at="$observed"
echo "[solution] Applied."
