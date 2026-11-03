#!/usr/bin/env bash
# Check: scout released version-2 through the staged steps and is Healthy.
set -uo pipefail
fail=0
r="$(kubectl -n starfleet get rollout scout -o json 2>/dev/null)" || { echo "FAIL: rollout scout not found"; exit 1; }

shape="$(echo "$r" | jq -c '[.spec.strategy.canary.steps[]? | if has("setWeight") then {w: .setWeight} elif has("pause") then {p: ((.pause.duration // "") | tostring | length > 0)} else {x: 1} end]')"
if [ "$shape" != '[{"w":25},{"p":true},{"w":50},{"p":true}]' ]; then
  echo "FAIL: steps must be setWeight 25, a timed pause, setWeight 50, a timed pause (found $shape)"
  fail=1
fi
image="$(echo "$r" | jq -r '.spec.template.spec.containers[0].image')"
message="$(echo "$r" | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="PODINFO_UI_MESSAGE") | .value')"
if [ "$image" != "ghcr.io/stefanprodan/podinfo:6.14.0" ] || [ "$message" != "version-2" ]; then
  echo "FAIL: the template must use ghcr.io/stefanprodan/podinfo:6.14.0 and the message version-2 (found $image, '$message')"
  fail=1
fi
phase="$(echo "$r" | jq -r '.status.phase // ""')"
stable="$(echo "$r" | jq -r '.status.stableRS // ""')"
current="$(echo "$r" | jq -r '.status.currentPodHash // ""')"
index="$(echo "$r" | jq -r '.status.currentStepIndex // -1')"
if [ "$phase" != "Healthy" ] || [ -z "$stable" ] || [ "$stable" != "$current" ]; then
  echo "FAIL: the release is not complete (phase=$phase stableRS=$stable currentPodHash=$current)"
  fail=1
fi
if [ "$index" != "4" ]; then
  echo "FAIL: the release must have walked all 4 steps (currentStepIndex=$index)"
  fail=1
fi
ready="$(kubectl -n starfleet get pods -l app=scout -o json | jq '[.items[] | select(.metadata.deletionTimestamp == null) | select(.spec.containers[0].image == "ghcr.io/stefanprodan/podinfo:6.14.0") | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length')"
if [ "$ready" != "4" ]; then
  echo "FAIL: $ready ready pods run version-2, expected 4"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: scout walked the 4 steps and 4 pods run version-2"
exit "$fail"
