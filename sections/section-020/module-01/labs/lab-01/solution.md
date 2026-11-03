# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-01/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: Read the starting state

```sh
kubectl -n starfleet get rollout scout shield
kubectl -n starfleet get rollout scout -o jsonpath='{.spec.strategy.canary.steps}{"\n"}'
kubectl -n starfleet get service shield-active shield-preview -o custom-columns=NAME:.metadata.name,HASH:.spec.selector.rollouts-pod-template-hash
```

Both Rollouts are `Healthy`. The only step of `scout` is `setWeight: 100`. The two blue-green Services show the same hash, because there is one ReplicaSet.

## Step 2: Release scout in stages

A JSON patch changes exactly the fields you name. Replace the steps and the template in one change so that one release uses the new steps:

```sh
kubectl -n starfleet patch rollout scout --type json -p '[
 {"op":"replace","path":"/spec/strategy/canary/steps","value":[{"setWeight":25},{"pause":{"duration":"15s"}},{"setWeight":50},{"pause":{"duration":"15s"}}]},
 {"op":"replace","path":"/spec/template/spec/containers/0/image","value":"ghcr.io/stefanprodan/podinfo:6.14.0"},
 {"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-2"}]'
kubectl -n starfleet get rollout scout -w
```

Watch `status.currentStepIndex` go from 0 to 4 and the phase change between `Progressing` and `Paused`. The pause steps end by themselves after 15 seconds. Wait for the end:

```sh
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Healthy rollout/scout --timeout=400s
kubectl -n starfleet get replicaset -l app=scout -L rollouts-pod-template-hash
```

The new ReplicaSet has 4 pods. `status.stableRS` equals `status.currentPodHash`. Grade it; `scout-canary-steps` passes.

## Step 3: Stage shield in preview

Add the two strategy fields and change the template:

```sh
kubectl -n starfleet patch rollout shield --type json -p '[
 {"op":"add","path":"/spec/strategy/blueGreen/autoPromotionEnabled","value":false},
 {"op":"add","path":"/spec/strategy/blueGreen/previewReplicaCount","value":1},
 {"op":"replace","path":"/spec/template/spec/containers/0/image","value":"ghcr.io/stefanprodan/podinfo:6.14.0"},
 {"op":"replace","path":"/spec/template/spec/containers/0/env/0/value","value":"version-2"}]'
kubectl -n starfleet wait --for=jsonpath='{.status.phase}'=Paused rollout/shield --timeout=240s
```

Read the result:

```sh
kubectl -n starfleet get service shield-active shield-preview -o custom-columns=NAME:.metadata.name,HASH:.spec.selector.rollouts-pod-template-hash
kubectl -n starfleet exec deploy/shuttle -- curl -s http://shield-preview:9898/
kubectl -n starfleet exec deploy/shuttle -- curl -s http://shield-active:9898/
```

The two Services have different hashes. The preview answer has the message `version-2`, and the active answer has `version-1`. Do not promote. Grade it; `shield-staged` passes.

## Step 4: Record the evidence

```sh
kubectl -n starfleet get rollout scout -o jsonpath='{.status.stableRS}{"\n"}'
kubectl -n starfleet get service shield-active -o jsonpath='{.spec.selector.rollouts-pod-template-hash}{"\n"}'
date -u +%Y-%m-%dT%H:%M:%SZ
kubectl -n starfleet create configmap rollout-record --from-literal=scout-stable-rs=<STABLE> --from-literal=shield-active-hash=<ACTIVE> --from-literal=observed-at=<TIME>
```

Replace the three placeholders with what the first three commands printed. Grade the whole lab. All four checks pass. If a Rollout changes after you wrote the record, the record no longer matches and `rollout-record` fails until you write it again.
