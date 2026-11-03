#!/usr/bin/env bash
# Check: the flag is on in the ConfigMap, in the mounted file and in the
# environment variable of the running flagcheck pod.
set -uo pipefail
fail=0
NS=starfleet
value="$(kubectl -n $NS get configmap scout-flags -o jsonpath="{.data.new-checkout}" 2>/dev/null)"
if [ "$value" != "on" ]; then
  echo "FAIL: key new-checkout in scout-flags is \"$value\", expected on"
  fail=1
fi
env_value="$(kubectl -n $NS exec deploy/flagcheck -- printenv FLAG_ENV 2>/dev/null)"
if [ "$env_value" != "on" ]; then
  echo "FAIL: FLAG_ENV in the running flagcheck pod is \"$env_value\", expected on"
  fail=1
fi
file_value="$(kubectl -n $NS exec deploy/flagcheck -- cat /etc/flags/new-checkout 2>/dev/null)"
if [ "$file_value" != "on" ]; then
  echo "FAIL: /etc/flags/new-checkout in the running pod is \"$file_value\", expected on"
  fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: the flag is on in the ConfigMap, the file and the environment"
exit "$fail"
