#!/usr/bin/env bash
# Check: probe runs the good image again, through a new revision (rollback), and
# its pods are ready. The check reads the running pods.
set -uo pipefail
fail=0
NS=starfleet
d="$(kubectl -n $NS get deployment probe -o json 2>/dev/null)" || { echo "FAIL: deployment probe not found"; exit 1; }

image="$(echo "$d" | jq -r '.spec.template.spec.containers[0].image')"
if [ "$image" != "ghcr.io/stefanprodan/podinfo:6.15.0" ]; then
  echo "FAIL: probe must run ghcr.io/stefanprodan/podinfo:6.15.0 again, found $image"
  fail=1
fi
revision="$(echo "$d" | jq -r '.metadata.annotations["deployment.kubernetes.io/revision"] // "0"')"
if [ "$revision" -lt 3 ]; then
  echo "FAIL: probe is at revision $revision; the rollback must create revision 3 or later"
  fail=1
fi
want="$(echo "$d" | jq -r '.spec.replicas')"
available="$(echo "$d" | jq -r '.status.availableReplicas // 0')"
total="$(echo "$d" | jq -r '.status.replicas // 0')"
if [ "$available" != "$want" ] || [ "$total" != "$want" ]; then
  echo "FAIL: probe has $available available of $total pods, expected $want"
  fail=1
fi
broken="$(kubectl -n $NS get pods -l app=probe -o json | jq '[.items[] | select(.metadata.deletionTimestamp == null) | select(.spec.containers[0].image | endswith("broken"))] | length')"
if [ "$broken" != "0" ]; then
  echo "FAIL: $broken probe pods still use the broken image"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: probe is back on the good image at revision $revision with $available ready pods"
exit "$fail"
