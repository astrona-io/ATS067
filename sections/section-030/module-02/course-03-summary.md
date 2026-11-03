---
draft: true
exam_objectives:
  - Pull vs. Event-driven
---
# Summary

- A poller checks on a timer and pays one request per check, with a delay of up to one interval. An event pushes a message when a change happens, with a short delay, but it can be lost. A timer stays useful as a safety net.
- Argo Events has an `EventSource` (receives), an `EventBus` (stores and delivers) and a `Sensor` (matches and acts). A source never calls a sensor directly.
- A webhook event source has one entry per event name, with `port`, `endpoint` and `method`. The block `spec.service` creates the Service `<name>-eventsource-svc` that clients call.
- An event has a context and a data part. For a webhook the data holds `header` and `body`. A sensor addresses a field with a path such as `body.ref`, which works for JSON bodies.
- A `Sensor` has dependencies (event source name and event name), optional filters and triggers. A Kubernetes trigger can `create`, `update`, `patch` or `delete`, and `parameters` copy event fields into the object with `src.dataKey` and `dest`.
- The sensor runs as the ServiceAccount in `spec.template.serviceAccountName`, which needs a Role for the operation and kind of the trigger.
- Delivery is at least once. A `create` with `generateName` runs twice on a repeated event. A `patch` of a named object leaves the same state. Choose the operation, the names and the guards so that a repeat is harmless.
- An event can ask a pull-based agent to look at Git now. The pull loop still applies the change.

<!-- astrona:playground:destroy -->
