# Overview: Event-Driven Triggers With Argo Events (Playground)

This is a **playground**, not a lab. It starts a cluster with Argo Events and a working event path, then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.
- Argo Events v1.9.11 (namespaced install) and the EventBus `default` (JetStream, 1 replica) in `argo-events`.
- The EventSource `fleet-hook`: a webhook named `deploy` on port 12000, endpoint `/deploy`, method POST, with a Service `fleet-hook-eventsource-svc`.
- The Sensor `fleet-sensor`: it depends on `fleet-hook/deploy` and creates a ConfigMap with the prefix `deploy-event-` in `starfleet`. The fields `service` and `ref` come from the body of the event.
- The ServiceAccount `sensor-runner` with a Role that can create, get, patch and update ConfigMaps in `starfleet`.
- A Deployment `shuttle` with `curl` in `starfleet`.

## Send an event

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -X POST \
  http://fleet-hook-eventsource-svc.argo-events.svc.cluster.local:12000/deploy \
  -H 'Content-Type: application/json' -d '{"service":"scout","ref":"main"}'
kubectl -n starfleet get configmap
```

## Practice tasks

- Read the logs of the pods of the event source and the sensor (`kubectl -n argo-events logs <pod>`).
- Send the same event twice and count the ConfigMaps. Then change the trigger to `patch` of a ConfigMap with a fixed name and compare.
- Add a filter on `body.ref` and send an event with another value.
- Delete the RoleBinding, send an event and read the error in the sensor logs.
- Send a body that is not JSON and read what the sensor does.
- Add a second webhook entry with another endpoint and send to both.
