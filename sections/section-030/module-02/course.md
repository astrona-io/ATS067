---
draft: true
exam_objectives:
  - Pull vs. Event-driven
---
# Event-Driven Triggers With Argo Events

This module explains how an event starts an action in a cluster instead of a timer. You will read how an `EventSource` receives a webhook, how the `EventBus` carries the event, how a `Sensor` matches it and how a trigger creates or patches an object. You will also read why a trigger must be safe to run twice. The hands-on steps use a kind cluster with Argo Events and a curl client that sends the events.

## Learning Goals

- Compare a timer that polls with an event that pushes, and name what each costs.
- Describe the role of the `EventSource`, the `EventBus`, the `Sensor` and the trigger.
- Read the shape of an event: its context and its `data` with `header` and `body`.
- Write a webhook `EventSource` with a `Service`, and a `Sensor` with a dependency, a filter and a Kubernetes trigger.
- Pass a field of the event into the object that a trigger creates.
- Explain at-least-once delivery and make a trigger safe to repeat.

## Before You Start

You should know what a custom resource, a ServiceAccount and a Role are. The hands-on steps use a playground with `kubectl`.

## Reading Order

1. Event Sources, The Event Bus And The Shape Of An Event
2. Sensors, Triggers And Safe Repeated Actions
3. Summary

<!-- astrona:playground -->
