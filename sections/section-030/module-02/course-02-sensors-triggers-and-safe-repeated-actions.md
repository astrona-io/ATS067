---
draft: true
exam_objectives:
  - Pull vs. Event-driven
---
# Sensors, Triggers And Safe Repeated Actions

A `Sensor` turns events into actions. It names the events it waits for, the conditions that must hold, and one or more triggers. This part explains each field, how event data flows into the object a trigger creates, and why the choice of operation decides whether a repeated event is harmless.

## A sensor with one dependency and one trigger

```yaml
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
  triggers:
    - template:
        name: record-event
        k8s:
          operation: create
          source:
            resource:
              apiVersion: v1
              kind: ConfigMap
              metadata:
                generateName: deploy-event-
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
```

## Dependencies

A dependency is a named subscription. `eventSourceName` and `eventName` select the events by the pair that the event source defined. The `name` is local to the sensor and is the handle that triggers and conditions use. One sensor can have several dependencies. By default the sensor fires when all of them have received an event. The field `circuit` (or `conditions` on a trigger) allows other combinations such as "a or b".

A dependency can hold filters that drop events that do not match:

```yaml
    - name: deploy-dep
      eventSourceName: fleet-hook
      eventName: deploy
      filters:
        data:
          - path: body.ref
            type: string
            value:
              - main
```

An event whose `body.ref` is not `main` is discarded and no trigger runs. A filter is the first place to keep unwanted events from reaching an action.

## Triggers

A trigger has a template with a name and one action. The Kubernetes trigger (`k8s`) works on a Kubernetes object and has four operations: `create` (the default), `update`, `patch` and `delete`. Other trigger types start an Argo Workflow, call an HTTP endpoint or send to a messaging system.

The field `source.resource` holds the object as a manifest. The sensor builds a new object from it each time the trigger runs.

## Parameters carry event data into the object

Each entry in `parameters` copies a value to a path inside the object:

- `src.dependencyName` says which dependency's event to read.
- `src.dataKey` is the path in the event data, for example `body.ref`. Without `dataKey`, the whole event data is used.
- `dest` is the path in the object. Numbers in the path address list items, for example `spec.containers.0.args.0`.

The values in the manifest are the defaults. A parameter overrides them. If the key is missing in the event, the sensor has nothing to copy and the trigger fails, so a filter or a check on the sender side prevents that.

## Permissions of the sensor

The sensor pod acts on the cluster with its own ServiceAccount, set in `spec.template.serviceAccountName`. That account needs a Role that allows exactly the operation and the kind of the trigger in the namespace of the object:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: sensor-runner
  namespace: starfleet
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["create", "get", "patch", "update"]
```

Without the permission the trigger fails with a `forbidden` error in the logs of the sensor pod, and nothing is created. Give the sensor the smallest Role that works, because anyone who can send an event to the source can cause the action.

## Create versus patch

The operation decides what a repeated event does.

| Operation | Name of the object | A second identical event |
| --- | --- | --- |
| `create` with `generateName` | A new random name each time | Creates a second object. The action ran twice |
| `create` with a fixed `name` | Always the same name | The second create fails because the object exists. The state is unchanged |
| `patch` of a named object | The object that already exists | Applies the same change again. The state is unchanged |
| `delete` of a named object | The object that exists | The first deletes it and the second finds nothing |

`patch` uses a patch strategy. The default is a merge patch, in which the fields in the source are merged into the live object. A patch trigger needs the name and the namespace of the target in `source.resource.metadata` and the fields to change.

## Safe repeated actions

Delivery is at least once, and a sender can retry. An action is safe to repeat when running it twice leaves the same state as running it once. This property is called idempotence. Ways to get it:

- Prefer an operation that sets a state (`patch` to a value) over one that adds something (`create` with `generateName`).
- Put an identity from the event into the name of the object, for example a commit hash, so that a repeat refers to the same object and fails or does nothing.
- Make the receiving side check before acting, for example "deploy this revision only if it is not already deployed".
- Keep the trigger small. An action that sends an email or charges a customer needs an external guard, because the sensor cannot undo it.

A trigger can also be rate limited with `rateLimit` (a number of runs per second, minute or hour) to protect the target from a burst of events.

## Retries and failure

If a trigger fails, the sensor retries when `retryStrategy` is set (steps, duration, factor). After the last attempt the failure is logged and, depending on the policy, the event is dropped. Failures are visible in the logs of the sensor pod and in the status of the sensor. An event that no trigger handled is not stored for a later replay by default, so critical flows need their own record.

## How this fits with a pull-based tool

An event can start a refresh of a pull-based tool. A Git server sends a webhook on a push and the pull-based agent re-reads the repository at once instead of on the next timer. The event shortens the delay, and the pull loop remains the safety net and the one that applies the change. The event only says "look now".

## Try it

In the playground:

1. Read the sensor with `kubectl -n argo-events get sensor fleet-sensor -o yaml`.
2. Send an event with `ref` set to `main` and list the ConfigMaps in `starfleet` with the prefix `deploy-event-`.
3. Send the same event twice and count the ConfigMaps.
4. Add a filter so that only `main` is accepted, and send an event with another `ref`.
5. Remove the Role binding and send an event. Read the error in the logs of the sensor pod.
6. Change the trigger to `patch` of a ConfigMap with a fixed name, send the event twice, and compare.
