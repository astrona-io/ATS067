#!/usr/bin/env bash
# Check: the ConfigMap release-evidence matches what the cluster does now.
set -uo pipefail
fail=0
NS=starfleet
NAME=release-evidence
if ! kubectl -n $NS get configmap $NAME >/dev/null 2>&1; then
  echo "FAIL: ConfigMap $NAME not found in $NS"
  exit 1
fi
read_key() { kubectl -n $NS get configmap $NAME -o json | jq -r --arg key "$1" ".data[\$key] // \"\""; }
strategy="$(read_key ledger-strategy)"
live_strategy="$(kubectl -n $NS get deployment ledger -o jsonpath="{.spec.strategy.type}")"
if [ "$strategy" != "$live_strategy" ]; then
  echo "FAIL: key ledger-strategy is \"$strategy\", the Deployment uses \"$live_strategy\""
  fail=1
fi
tag="$(read_key ledger-image-tag)"
live_image="$(kubectl -n $NS get deployment ledger -o jsonpath="{.spec.template.spec.containers[0].image}")"
if [ "$tag" != "${live_image##*:}" ]; then
  echo "FAIL: key ledger-image-tag is \"$tag\", the Deployment runs \"${live_image##*:}\""
  fail=1
fi
flag="$(read_key flag-new-checkout)"
live_flag="$(kubectl -n $NS exec deploy/flagcheck -- printenv FLAG_ENV 2>/dev/null)"
if [ "$flag" != "$live_flag" ]; then
  echo "FAIL: key flag-new-checkout is \"$flag\", the running pod sees \"$live_flag\""
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: the release evidence matches the cluster"
exit "$fail"
