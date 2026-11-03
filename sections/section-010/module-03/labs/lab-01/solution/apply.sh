#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet patch deployment ledger --type merge -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
kubectl -n starfleet set image deployment/ledger ledger=ghcr.io/stefanprodan/podinfo:6.14.0
kubectl -n starfleet rollout status deployment/ledger --timeout=240s

kubectl -n starfleet patch configmap scout-flags --type merge -p '{"data":{"new-checkout":"on"}}'
kubectl -n starfleet rollout restart deployment/flagcheck
kubectl -n starfleet rollout status deployment/flagcheck --timeout=180s

kubectl -n starfleet create configmap release-evidence \
  --from-literal=ledger-strategy=Recreate \
  --from-literal=ledger-image-tag=6.14.0 \
  --from-literal=flag-new-checkout=on
echo "[solution] Applied."
