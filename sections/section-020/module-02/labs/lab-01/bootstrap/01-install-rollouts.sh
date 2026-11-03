#!/usr/bin/env bash
# Plumbing: install the Argo Rollouts controller v1.10.0 (the manifest is
# checked against a SHA-256 checksum). The kubectl plugin is not installed.
set -euo pipefail
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f - >/dev/null
manifest_path="$(mktemp)"
curl --fail --silent --show-error --location --max-time 120 \
  'https://github.com/argoproj/argo-rollouts/releases/download/v1.10.0/install.yaml' -o "$manifest_path"
actual="$(shasum -a 256 "$manifest_path" | cut -d' ' -f1)"
if [ "$actual" != "ca8a1785391026023627c8a12db5422e227d7a7a6ec7c01f99f7d5b1726ed53c" ]; then
  echo "Controller manifest checksum differs" >&2
  exit 1
fi
kubectl apply --server-side -n argo-rollouts -f "$manifest_path" >/dev/null
rm -f "$manifest_path"
kubectl -n argo-rollouts rollout status deployment/argo-rollouts --timeout=300s
