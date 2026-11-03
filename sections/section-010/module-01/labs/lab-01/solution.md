# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-01/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you repair the releases.

## Step 1: Find out why scout is stuck

Look at the pods and the Deployment conditions:

```sh
kubectl -n starfleet get pods -l app=scout
kubectl -n starfleet rollout status deployment/scout --timeout=20s
```

The list has two old pods that are ready and one new pod that is `Running` but shows `0/1` in the `READY` column. The status command reports that it waits for the rollout. Read the events of the new pod:

```sh
kubectl -n starfleet describe pod -l app=scout
```

One event says `Readiness probe failed` with the HTTP status code `404`. The container runs and the image is fine. The readiness probe tests the path `/ready-check`, which the application does not serve. The strategy `maxSurge: 0` and `maxUnavailable: 1` also made the controller remove an old pod before the new one was ready, so the Service has fewer pods than it had.

## Step 2: Fix scout

Save this as `scout-fix.yaml`. It is a patch: it changes only the fields that you name.

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
        - name: scout
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
```

Apply it and wait for the rollout:

```sh
kubectl -n starfleet patch deployment scout --patch-file scout-fix.yaml
kubectl -n starfleet rollout status deployment/scout --timeout=240s
```

The patch changes the pod template, so the controller starts a new rollout. With the correct probe path, the new pods become ready and the old ones go away one at a time. The command returns when 3 updated replicas are available. Check the result:

```sh
kubectl -n starfleet get deployment scout -o jsonpath='{.status.updatedReplicas} {.status.availableReplicas} {.spec.strategy.rollingUpdate}{"\n"}'
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-01/labs/lab-01 --keep
```

The checks `scout-rollout-complete` and `scout-rollout-settings` now pass.

## Step 3: Roll probe back

List the revisions of `probe` and read the template of revision 1:

```sh
kubectl -n starfleet rollout history deployment/probe
kubectl -n starfleet rollout history deployment/probe --revision=1
```

Revision 1 has the image `ghcr.io/stefanprodan/podinfo:6.15.0`. Revision 2 has the image with the tag `6.15.0-broken`. The undo goes back one revision, which is revision 1 here:

```sh
kubectl -n starfleet rollout undo deployment/probe
kubectl -n starfleet rollout status deployment/probe --timeout=240s
```

The controller reuses the ReplicaSet of revision 1 and gives it the revision number 3. The history now lists revisions 2 and 3, and revision 1 is gone because its ReplicaSet became revision 3. Grade it; the check `probe-rolled-back` passes.

## Step 4: Record the release

Read the live revision numbers and the time, then create the ConfigMap with the values you read:

```sh
kubectl -n starfleet get deployment scout probe -o custom-columns=NAME:.metadata.name,REVISION:.metadata.annotations.deployment\.kubernetes\.io/revision
date -u +%Y-%m-%dT%H:%M:%SZ
```

Replace `<SCOUT_REVISION>`, `<PROBE_REVISION>` and `<TIME>` with what these commands printed:

```sh
kubectl -n starfleet create configmap release-record --from-literal=scout-revision=<SCOUT_REVISION> --from-literal=probe-revision=<PROBE_REVISION> --from-literal=observed-at=<TIME>
```

Grade the whole lab. All five checks pass. If you change a Deployment after you wrote the record, the revision number changes and the check `release-record` fails until you write the record again.
