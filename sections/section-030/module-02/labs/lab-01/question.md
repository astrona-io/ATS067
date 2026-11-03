# Question

Solve this question on: `terminal`

Argo Events runs in `argo-events` with the EventBus `default`. In `starfleet`, a `curl` client runs as the Deployment `shuttle`, the ConfigMap `deploy-state` holds `service: none` and `ref: none`, and the ServiceAccount `sensor-runner` in `argo-events` may create, get, patch and update ConfigMaps in `starfleet`. There is no EventSource and no Sensor. Do not delete the EventBus or the ConfigMap.

1. Create an `EventSource` named `fleet-hook` in `argo-events`. It has one webhook entry named `deploy` on port `12000`, endpoint `/deploy` and method `POST`, and a `service` that exposes port 12000.

2. Create a `Sensor` named `fleet-sensor` in `argo-events` that runs as `sensor-runner` and:
   - depends on the event `deploy` of the event source `fleet-hook`, and keeps only events whose `body.ref` is `main` (a data filter);
   - has a Kubernetes trigger with the operation `patch` on the ConfigMap `deploy-state` in `starfleet`;
   - copies `body.service` to `data.service` and `body.ref` to `data.ref`.

3. From the client pod, send the events to the Service of the event source: one with `{"service":"hull","ref":"dev"}`, then one with `{"service":"scout","ref":"main"}`, and send the second one twice. Wait until `deploy-state` holds `service: scout` and `ref: main`. The event with `ref` set to `dev` must not change it, and no new ConfigMaps may be created.

`kubectl` already points at the cluster as the cluster administrator.

Check your work with `astrona submit`.
