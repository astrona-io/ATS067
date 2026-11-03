# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/capstone/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: Heal the drift

```sh
kubectl -n argocd get application scout
kubectl -n starfleet get deployment scout
kubectl -n argocd patch application scout --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
kubectl -n starfleet get deployment scout -w
```

The Application is `OutOfSync` because the live replica count (6) differs from Git (2). With manual sync nothing reverts it. After the patch the controller sees an application that is out of sync, applies the manifest from Git and the count returns to 2. Grade it; the check `drift-healed` passes.

## Step 2: Release through Git

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/fleet-config.git
cd fleet-config
sed -i.bak 's/value: version-1/value: version-2/' apps/scout/deployment.yaml
rm apps/scout/deployment.yaml.bak
git commit -am "scout: message version-2"
git push origin main
git rev-parse HEAD
kubectl -n argocd annotate application scout argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd get application scout -o jsonpath='{.status.sync.status} {.status.sync.revision}{"\n"}'
```

After the refresh the Application becomes `OutOfSync`, syncs and ends `Synced` with the revision that `git rev-parse HEAD` printed. The pods are replaced with the new message. Grade it; the check `git-release-applied` passes.

## Step 3: The event path

```sh
kubectl apply -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: ref-hook
  namespace: argo-events
spec:
  service:
    ports:
      - port: 12000
        targetPort: 12000
  webhook:
    release:
      port: "12000"
      endpoint: /release
      method: POST
---
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: ref-sensor
  namespace: argo-events
spec:
  template:
    serviceAccountName: sensor-runner
  dependencies:
    - name: release-dep
      eventSourceName: ref-hook
      eventName: release
  triggers:
    - template:
        name: set-state
        k8s:
          operation: patch
          source:
            resource:
              apiVersion: v1
              kind: ConfigMap
              metadata:
                name: deploy-state
                namespace: starfleet
              data:
                service: unset
                ref: unset
          parameters:
            - src:
                dependencyName: release-dep
                dataKey: body.service
              dest: data.service
            - src:
                dependencyName: release-dep
                dataKey: body.ref
              dest: data.ref
YAML
kubectl -n argo-events get pods
```

Wait until the pods of the event source and the sensor are ready. Grade it; the check `event-path-defined` passes.

## Step 4: Send the event twice

```sh
SHA="$(git rev-parse HEAD)"
URL=http://ref-hook-eventsource-svc.argo-events.svc.cluster.local:12000/release
for i in 1 2; do
  kubectl -n starfleet exec deploy/shuttle -- curl -s -X POST "$URL" -H 'Content-Type: application/json' -d "{\"service\":\"scout\",\"ref\":\"$SHA\"}"
done
kubectl -n starfleet get configmap deploy-state -o jsonpath='{.data}{"\n"}'
```

Both events patch the same ConfigMap with the same values, so the second one changes nothing. A `create` trigger with `generateName` would have left two ConfigMaps. Grade the whole lab. All five checks pass.
