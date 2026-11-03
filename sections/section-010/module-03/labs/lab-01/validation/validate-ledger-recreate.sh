#!/usr/bin/env bash
# Check: ledger uses Recreate and the image 6.14.0 with 2 ready replicas.
set -uo pipefail
fail=0
NS=starfleet
type="$(kubectl -n $NS get deployment ledger -o jsonpath="{.spec.strategy.type}" 2>/dev/null)"
if [ "$type" != "Recreate" ]; then
  echo "FAIL: strategy type of ledger is \"$type\", expected Recreate"
  fail=1
fi
rolling="$(kubectl -n $NS get deployment ledger -o jsonpath="{.spec.strategy.rollingUpdate}" 2>/dev/null)"
if [ -n "$rolling" ]; then
  echo "FAIL: ledger still has a rollingUpdate section"
  fail=1
fi
image="$(kubectl -n $NS get deployment ledger -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
if [ "$image" != "ghcr.io/stefanprodan/podinfo:6.14.0" ]; then
  echo "FAIL: image of ledger is \"$image\", expected ghcr.io/stefanprodan/podinfo:6.14.0"
  fail=1
fi
ready="$(kubectl -n $NS get deployment ledger -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
updated="$(kubectl -n $NS get deployment ledger -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
if [ "$ready" != "2" ] || [ "$updated" != "2" ]; then
  echo "FAIL: ledger needs 2 ready and 2 updated replicas (ready=\"${ready:-0}\" updated=\"${updated:-0}\")"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: ledger runs 6.14.0 with the Recreate strategy"
exit "$fail"
