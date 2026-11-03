---
draft: true
exam_objectives:
  - Pull vs. Event-driven
---
# Event Sources, The Event Bus And The Shape Of An Event

A pull loop asks "is there a change?" on a timer. An event-driven system waits until something tells it that a change happened. This part shows the parts of Argo Events that receive a message, carry it and hand it on, and what an event looks like when it arrives.

## Polling and events differ in when work starts

A poller repeats a check at a fixed interval. The delay between a change and its detection is up to one interval, and every check costs a request even when nothing changed. A short interval lowers the delay and raises the load. A long interval does the reverse.

An event is a message that a producer sends when a change happens. The consumer does work only when a message arrives, and the delay is the time to deliver the message. The cost is that the producer must be able to send, the consumer must be reachable, and a lost message means a lost change. A timer is therefore still useful as a safety net: Argo CD keeps its 3-minute refresh even when a webhook is set, so a missed webhook costs at most one interval.

## The four parts of Argo Events

| Part | Kind | Job |
| --- | --- | --- |
| Event source | `EventSource` | Listens for something outside or inside the cluster (an HTTP request, a Git push, a timer, a change of a Kubernetes object) and turns it into an event |
| Event bus | `EventBus` | Stores the events and delivers them to the sensors that subscribe |
| Sensor | `Sensor` | Subscribes to events, decides whether the conditions are met and runs triggers |
| Trigger | part of a `Sensor` | The action: create, patch or delete a Kubernetes object, start a workflow, call an HTTP endpoint and others |

The controller `controller-manager` in the namespace `argo-events` watches these resources. For each `EventSource` and each `Sensor` it starts a workload (a Deployment) that does the work. An event source never calls a sensor directly. It publishes to the bus, and the sensor reads from the bus, so the two can be changed, restarted and scaled on their own.

## The event bus

An `EventBus` named `default` in the namespace is used by every source and sensor in that namespace. The recommended implementation is JetStream, a persistent stream of the NATS server:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: EventBus
metadata:
  name: default
  namespace: argo-events
spec:
  jetstream:
    version: latest
    replicas: 1
```

Because the stream is persistent, an event that was published while a sensor was restarting is still there when the sensor returns. The stream keeps events for a limited time (`maxAge`). The bus must be ready before an event source or a sensor can start, so the first check of a broken setup is the status of the `EventBus`.

## A webhook event source

```yaml
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
```

- The name under `webhook` (here `deploy`) is the event name. A sensor refers to the pair of event source name and event name.
- `port` and `endpoint` say where the HTTP server inside the event source listens. One event source can hold several entries, each with its own endpoint.
- `method` limits the HTTP method. A request with another method is refused.
- `spec.service` makes the controller create a Kubernetes Service in front of the event source pod. Without it, nothing inside the cluster can reach the pod by a stable name. The Service is named after the event source with the suffix `-eventsource-svc`, so here it is `fleet-hook-eventsource-svc`.

A client in the cluster sends the event with an HTTP request:

```sh
curl -X POST http://fleet-hook-eventsource-svc.argo-events.svc.cluster.local:12000/deploy \
  -H 'Content-Type: application/json' \
  -d '{"service":"scout","ref":"main"}'
```

The event source answers when it has accepted the request and published the event. A source for a Git server works the same way with a different entry, for example for GitHub or Gitea webhooks, and checks the signature of the sender.

## The shape of an event

Every event has a context and a data part. The context says what the event is and where it came from: an `id`, the `source`, the `type`, the `subject` (the event name), the `time` and the content type of the data. The data part of a webhook holds the HTTP request:

```json
{
  "header": { "Content-Type": ["application/json"], "User-Agent": ["curl/8.22.0"] },
  "body": { "service": "scout", "ref": "main" }
}
```

A sensor addresses a field with a path from the data part, for example `body.ref`. If the content type is JSON, the body is a JSON object that can be addressed field by field. If the sender used another content type, the body is a text and cannot be addressed by field.

## Delivery guarantees

The bus delivers an event to a sensor at least once. After a failure or a restart, a sensor can see an event again. The sender can also send the same request twice, for example after a timeout. A design that needs an action to happen exactly once must therefore make the action safe to repeat.

## Permissions

The event source pod needs no permission to change objects in the cluster for a webhook, because it only listens and publishes. Event sources that watch Kubernetes objects need read access for the kinds they watch. Keep the permissions of each component to its own job.

## Try it

In the playground:

1. Run `kubectl -n argo-events get eventbus,eventsource,sensor` and read the status of each.
2. Run `kubectl -n argo-events get pods` and find the pods of the bus, the event source and the sensor.
3. Run `kubectl -n argo-events get svc` and find the service of the event source.
4. Send the request above from the curl client with `kubectl -n starfleet exec deploy/shuttle -- curl ...`.
5. Read the logs of the event source pod and of the sensor pod and find the event.
6. Send a GET request to the endpoint and read the answer.
