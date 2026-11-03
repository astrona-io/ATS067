# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-03/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you make the changes.

## Step 1: Read the current state

```sh
kubectl -n starfleet get deployment ledger -o jsonpath='{.spec.strategy}{"\n"}'
kubectl -n starfleet get deployment ledger -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl -n starfleet get configmap scout-flags -o jsonpath='{.data}{"\n"}'
kubectl -n starfleet exec deploy/flagcheck -- printenv FLAG_ENV
```

The strategy is `RollingUpdate` with a `rollingUpdate` section, the image tag is `6.15.0` and the flag is `off`.

## Step 2: Switch ledger to Recreate and release the new image

The API server rejects the `Recreate` type while the `rollingUpdate` section exists. One merge patch sets the type and removes the section with `null`:

```sh
kubectl -n starfleet patch deployment ledger --type merge -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
kubectl -n starfleet set image deployment/ledger ledger=ghcr.io/stefanprodan/podinfo:6.14.0
kubectl -n starfleet rollout status deployment/ledger --timeout=240s
```

The controller stops both old pods before it creates the new ones, so for a short time `ledger` has no ready pod. Grade it; the check `ledger-recreate` passes.

## Step 3: Turn the flag on and replace the pods

Save this as `scout-flags.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-flags
  namespace: starfleet
data:
  new-checkout: "on"
```

Apply it:

```sh
kubectl apply -f scout-flags.yaml
```

The mounted file changes after the kubelet refresh, but the environment variable of the running pod stays `off`. Replace the pod so that it starts with the new value:

```sh
kubectl -n starfleet rollout restart deployment/flagcheck
kubectl -n starfleet rollout status deployment/flagcheck --timeout=180s
kubectl -n starfleet exec deploy/flagcheck -- printenv FLAG_ENV
kubectl -n starfleet exec deploy/flagcheck -- cat /etc/flags/new-checkout
```

Both reads print `on`. A new pod mounts the ConfigMap when it starts, so the file is also current. Grade it; the check `flag-live` passes.

## Step 4: Record the evidence

```sh
kubectl -n starfleet create configmap release-evidence --from-literal=ledger-strategy=Recreate --from-literal=ledger-image-tag=6.14.0 --from-literal=flag-new-checkout=on
```

Grade the whole lab. All four checks pass. If you change the strategy, the image or the flag after you wrote the record, the record no longer matches the cluster and the check `release-evidence` fails until you write it again.
