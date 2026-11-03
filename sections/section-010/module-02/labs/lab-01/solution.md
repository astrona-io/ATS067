# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-02/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`. It stays your guard while you change the Services.

## Step 1: See what each Service selects

```sh
kubectl -n starfleet get service scout probe -o custom-columns=NAME:.metadata.name,SELECTOR:.spec.selector
kubectl -n starfleet get pods -L track
kubectl -n starfleet get endpointslices
```

The Service `scout` selects `app: scout` and `track: blue`, so only the blue pods are its endpoints. The Service `probe` selects `app: probe` and `track: stable`, so the canary pod could never receive traffic, even if it existed. The canary Deployment has 0 replicas.

## Step 2: Switch scout to green

The selector is a map. A merge patch changes only the keys that you name, so this sets `track` to `green` and keeps `app`:

```sh
kubectl -n starfleet patch service scout --type merge -p '{"spec":{"selector":{"track":"green"}}}'
kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=scout -o wide
```

The endpoints controller recomputes the endpoints, and the new connections go to the two green pods. Nothing happens to the blue pods: they keep running and are ready. Grade it; the check `active-track-green` passes.

## Step 3: Fix probe and start the canary

Remove the `track` key from the selector, so that the Service matches the stable pods and the canary pods. The JSON patch removes exactly one key:

```sh
kubectl -n starfleet patch service probe --type json -p '[{"op":"remove","path":"/spec/selector/track"}]'
kubectl -n starfleet scale deployment/probe-canary --replicas=1
kubectl -n starfleet rollout status deployment/probe-canary --timeout=240s
```

Each connection goes to one ready endpoint, and the endpoints are 3 stable pods and 1 canary pod. The share of the canary is 1 of 4, which is 25 percent. Check the endpoints:

```sh
kubectl -n starfleet get endpointslices -l kubernetes.io/service-name=probe -o json | jq '[.items[].endpoints[] | select(.conditions.ready == true)] | length'
```

The result is `4`. Grade it; the check `canary-share` passes.

## Step 4: Record the evidence

```sh
date -u +%Y-%m-%dT%H:%M:%SZ
kubectl -n starfleet create configmap release-evidence --from-literal=active-track=green --from-literal=canary-percent=25 --from-literal=observed-at=<TIME>
```

Replace `<TIME>` with the time the first command printed. Grade the whole lab. All four checks pass. If you change a selector or the canary replicas after you wrote the record, the record no longer matches the cluster and the check `release-evidence` fails until you write it again.
