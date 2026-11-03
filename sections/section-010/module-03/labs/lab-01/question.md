# Question

Solve this question on: `terminal`

The namespace `starfleet` runs the Deployment `ledger`, which holds a lock that two pods must never share, and the Deployment `flagcheck`, which reads the feature flag in the ConfigMap `scout-flags`. Do not delete any Deployment.

1. The Deployment `ledger` uses the `RollingUpdate` strategy, so two versions can overlap. Change it to the `Recreate` strategy and release the image `ghcr.io/stefanprodan/podinfo:6.14.0`. The release must finish with 2 ready replicas.

2. Turn the feature flag on: set the key `new-checkout` in the ConfigMap `scout-flags` to `on`. The running pod of `flagcheck` must see the flag as `on` both in the environment variable `FLAG_ENV` and in the file `/etc/flags/new-checkout`.

3. Record the result in a ConfigMap `release-evidence` in `starfleet` with these keys:
   - `ledger-strategy`: the strategy type of `ledger` now.
   - `ledger-image-tag`: the tag of the image that `ledger` runs now, for example `6.15.0`.
   - `flag-new-checkout`: the value of the flag as the running `flagcheck` pod sees it in its environment.

`kubectl` already points at the cluster as the cluster administrator.

Check your work with `astrona submit`.
