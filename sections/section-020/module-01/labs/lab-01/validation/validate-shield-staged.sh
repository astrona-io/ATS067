#!/usr/bin/env bash
# Check: shield stages version-2 in preview and waits for promotion. The active
# Service still reaches only the 4 version-1 pods.
set -uo pipefail
fail=0
NS=starfleet
r="$(kubectl -n $NS get rollout shield -o json 2>/dev/null)" || { echo "FAIL: rollout shield not found"; exit 1; }

auto="$(echo "$r" | jq -r '.spec.strategy.blueGreen.autoPromotionEnabled // "unset" | tostring')"
count="$(echo "$r" | jq -r '.spec.strategy.blueGreen.previewReplicaCount // 0')"
image="$(echo "$r" | jq -r '.spec.template.spec.containers[0].image')"
message="$(echo "$r" | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="PODINFO_UI_MESSAGE") | .value')"
[ "$auto" = "false" ] || { echo "FAIL: autoPromotionEnabled must be false (found $auto)"; fail=1; }
[ "$count" = "1" ] || { echo "FAIL: previewReplicaCount must be 1 (found $count)"; fail=1; }
if [ "$image" != "ghcr.io/stefanprodan/podinfo:6.14.0" ] || [ "$message" != "version-2" ]; then
  echo "FAIL: the template must use ghcr.io/stefanprodan/podinfo:6.14.0 and the message version-2"
  fail=1
fi
phase="$(echo "$r" | jq -r '.status.phase // ""')"
[ "$phase" = "Paused" ] || { echo "FAIL: shield must wait for promotion in the phase Paused (found '$phase')"; fail=1; }

ready_images() {
  local pods
  pods="$(kubectl -n $NS get endpointslices -l kubernetes.io/service-name="$1" -o json | jq -r '.items[].endpoints[]? | select(.conditions.ready == true) | .targetRef.name')"
  for pod in $pods; do kubectl -n $NS get pod "$pod" -o jsonpath='{.spec.containers[0].image}{"\n"}' 2>/dev/null; done
}
active="$(ready_images shield-active | sort | uniq -c | tr -s ' ' | tr '\n' ';')"
if [ "$active" != " 4 ghcr.io/stefanprodan/podinfo:6.15.0;" ]; then
  echo "FAIL: shield-active must reach 4 pods of ghcr.io/stefanprodan/podinfo:6.15.0 (found $active)"
  fail=1
fi
preview="$(ready_images shield-preview | sort | uniq -c | tr -s ' ' | tr '\n' ';')"
if [ "$preview" != " 1 ghcr.io/stefanprodan/podinfo:6.14.0;" ]; then
  echo "FAIL: shield-preview must reach 1 pod of ghcr.io/stefanprodan/podinfo:6.14.0 (found $preview)"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: version-2 waits in preview with 1 pod and active serves version-1"
exit "$fail"
