#!/usr/bin/env bash
# Check: the warp rollout finished with the intended version. The pods that
# run now (not terminating) must all be ready and carry the new template.
set -uo pipefail
fail=0
NS=starfleet

d="$(kubectl -n $NS get deployment warp -o json 2>/dev/null)" || { echo "FAIL: deployment warp not found"; exit 1; }

gen="$(echo "$d" | jq -r '.metadata.generation')"
seen="$(echo "$d" | jq -r '.status.observedGeneration // 0')"
want="$(echo "$d" | jq -r '.spec.replicas')"
updated="$(echo "$d" | jq -r '.status.updatedReplicas // 0')"
total="$(echo "$d" | jq -r '.status.replicas // 0')"
available="$(echo "$d" | jq -r '.status.availableReplicas // 0')"
if [ "$gen" != "$seen" ] || [ "$updated" != "$want" ] || [ "$total" != "$want" ] || [ "$available" != "$want" ]; then
  echo "FAIL: rollout not complete (replicas=$total updated=$updated available=$available desired=$want)"
  fail=1
fi

image="$(echo "$d" | jq -r '.spec.template.spec.containers[0].image')"
if [ "$image" != "ghcr.io/stefanprodan/podinfo:6.15.0" ]; then
  echo "FAIL: warp must run ghcr.io/stefanprodan/podinfo:6.15.0, found $image"
  fail=1
fi
message="$(echo "$d" | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="PODINFO_UI_MESSAGE") | .value')"
if [ "$message" != "version-2" ]; then
  echo "FAIL: PODINFO_UI_MESSAGE must stay version-2, found '$message'"
  fail=1
fi
path="$(echo "$d" | jq -r '.spec.template.spec.containers[0].readinessProbe.httpGet.path // ""')"
if [ "$path" != "/readyz" ]; then
  echo "FAIL: the readiness probe must test /readyz, found '$path'"
  fail=1
fi

ready_pods="$(kubectl -n $NS get pods -l app=warp -o json | jq '[.items[] | select(.metadata.deletionTimestamp == null) | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length')"
if [ "$ready_pods" != "$want" ]; then
  echo "FAIL: $ready_pods ready warp pods, expected $want"
  fail=1
fi

[ "$fail" -eq 0 ] && echo "PASS: warp rolled out version-2 with $want ready pods"
exit "$fail"
