#!/usr/bin/env bash
# Check: the ConfigMap release-record in scout-prod matches the live state.
set -uo pipefail
fail=0
NS=scout-prod
c="$(kubectl -n $NS get configmap release-record -o json 2>/dev/null)" || { echo "FAIL: ConfigMap release-record not found in $NS"; exit 1; }
rev="$(kubectl -n argocd get application scout-prod -o jsonpath='{.status.sync.revision}')"
rec="$(echo "$c" | jq -r '.data["prod-revision"] // ""')"
{ [ -n "$rec" ] && [ "$rec" = "$rev" ]; } || { echo "FAIL: key prod-revision is '$rec', the Application revision is '$rev'"; fail=1; }
msg="$(kubectl -n $NS get deployment scout -o json | jq -r '.spec.template.spec.containers[0].env[]? | select(.name=="PODINFO_UI_MESSAGE") | .value')"
rec="$(echo "$c" | jq -r '.data["prod-message"] // ""')"
{ [ -n "$rec" ] && [ "$rec" = "$msg" ]; } || { echo "FAIL: key prod-message is '$rec', the Deployment runs '$msg'"; fail=1; }
[ "$fail" -eq 0 ] && echo "PASS: the release record matches the cluster"
exit "$fail"
