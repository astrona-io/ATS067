# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/capstone/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you repair the workloads.

## Step 1: Find out why warp is stuck

```sh
kubectl -n starfleet get pods -l app=warp
kubectl -n starfleet describe pod -l app=warp
```

Two old pods are ready and one new pod is `Running` with `0/1` in the `READY` column. The events of the new pod say `Readiness probe failed` with the HTTP status code `404`: the probe tests the path `/ready-check`, which the application does not serve. The strategy `maxSurge: 0` with `maxUnavailable: 1` also removes a serving pod before the new pod is ready.

## Step 2: Fix warp

Save this as `warp-fix.yaml`:

```yaml
spec:
  minReadySeconds: 5
  progressDeadlineSeconds: 120
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
        - name: warp
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
```

```sh
kubectl -n starfleet patch deployment warp --patch-file warp-fix.yaml
kubectl -n starfleet rollout status deployment/warp --timeout=240s
```

The patch changes the pod template, so a new rollout starts. With the correct path, the new pods become ready and the old ones go away one at a time. Grade it; the checks `warp-rollout-complete` and `warp-rollout-settings` pass.

## Step 3: Roll impulse back

```sh
kubectl -n starfleet rollout history deployment/impulse
kubectl -n starfleet rollout history deployment/impulse --revision=1
kubectl -n starfleet rollout undo deployment/impulse
kubectl -n starfleet rollout status deployment/impulse --timeout=240s
```

Revision 1 has the image `ghcr.io/stefanprodan/podinfo:6.15.0`; revision 2 has the tag `6.15.0-broken`. The undo reuses the ReplicaSet of revision 1 and gives it the revision number 3. Grade it; the check `impulse-rolled-back` passes.

## Step 4: Switch shield to green

```sh
kubectl -n starfleet get service shield -o jsonpath='{.spec.selector}{"\n"}'
kubectl -n starfleet patch service shield --type merge -p '{"spec":{"selector":{"track":"green"}}}'
kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=shield
```

The merge patch changes only the key `track` and keeps `app`. The endpoints controller recomputes the endpoints: new connections go to the two green pods. The blue pods keep running. Grade it; the check `shield-switched` passes.

## Step 5: Record the release

Write the record last. The revision numbers must match the live state when the check runs.

```sh
kubectl -n starfleet get deployment warp impulse -o custom-columns=NAME:.metadata.name,REVISION:.metadata.annotations.deployment\.kubernetes\.io/revision
date -u +%Y-%m-%dT%H:%M:%SZ
kubectl -n starfleet create configmap release-record --from-literal=warp-revision=<WARP_REVISION> --from-literal=impulse-revision=<IMPULSE_REVISION> --from-literal=shield-track=green --from-literal=observed-at=<TIME>
```

Replace the three placeholders with what the first two commands printed. Grade the whole lab. All six checks pass. If you change a Deployment or the Service after you wrote the record, the record no longer matches and the check `release-record` fails until you write it again.
