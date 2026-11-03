# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-02/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: The event source

```sh
kubectl apply -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: fleet-hook
  namespace: argo-events
spec:
  service:
    ports:
      - port: 12000
        targetPort: 12000
  webhook:
    deploy:
      port: "12000"
      endpoint: /deploy
      method: POST
YAML
kubectl -n argo-events get eventsource,pods,svc
```

The controller starts a pod for the event source and creates the Service `fleet-hook-eventsource-svc`. The name under `webhook` (`deploy`) is the event name. Grade it; the check `eventsource-defined` passes.

## Step 2: The sensor

```sh
kubectl apply -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: fleet-sensor
  namespace: argo-events
spec:
  template:
    serviceAccountName: sensor-runner
  dependencies:
    - name: deploy-dep
      eventSourceName: fleet-hook
      eventName: deploy
      filters:
        data:
          - path: body.ref
            type: string
            value:
              - main
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
                dependencyName: deploy-dep
                dataKey: body.service
              dest: data.service
            - src:
                dependencyName: deploy-dep
                dataKey: body.ref
              dest: data.ref
YAML
```

The `patch` operation needs the name and namespace of the target in the source. The values `unset` are defaults that the parameters replace. Wait until the pod of the sensor is ready (`kubectl -n argo-events get pods`). Grade it; the check `sensor-defined` passes.

## Step 3: Send the events

```sh
URL=http://fleet-hook-eventsource-svc.argo-events.svc.cluster.local:12000/deploy
send() { kubectl -n starfleet exec deploy/shuttle -- curl -s -X POST "$URL" -H 'Content-Type: application/json' -d "$1"; }
send '{"service":"hull","ref":"dev"}'
send '{"service":"scout","ref":"main"}'
send '{"service":"scout","ref":"main"}'
kubectl -n starfleet get configmap deploy-state -o jsonpath='{.data}{"\n"}'
kubectl -n starfleet get configmap
```

The first event is dropped by the filter, because its `ref` is `dev`. The other two pass and patch the ConfigMap. The second patch writes the same values again, so the state does not change: the action is safe to repeat. The list of ConfigMaps has no `deploy-event-` entries, because a patch changes one named object and creates nothing. If `deploy-state` does not change, read the logs of the sensor pod and look for a `forbidden` error or a missing key. Grade the whole lab. All four checks pass.
