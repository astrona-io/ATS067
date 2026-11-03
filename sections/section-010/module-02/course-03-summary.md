---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# Summary

A blue-green release runs the old and the new version as two complete Deployments with different `track` labels. An active Service and a preview Service select one track each. The switch is a change of one Service selector. The endpoints controller rebuilds the endpoint list and each node updates its network rules, so new connections reach the new version within a short time. Open connections stay on the old pods. The old version needs to keep running for a while, and the switch does not undo data changes.

A canary release sends a small share of requests to the new version. With plain Services, the share follows the number of pods behind the Service selector. The observed share differs from the calculated one because of random endpoint choice, connection reuse and unequal requests, and it changes when either Deployment is scaled. Exact weights need a routing component that supports them.

Evidence decides every release. Error rate, latency percentiles, saturation and business outcomes must be compared with the stable version for similar requests over enough time. Promotion and stop conditions are written before exposure. Rolling updates, blue-green and canary releases differ in the capacity they need, the number of users they can affect and how fast they can be reversed. None of them removes the need for compatible data changes.

Key facts:

- A Service routes to every ready pod whose labels match its selector.
- The selector switch moves new connections, not open ones and not data.
- A canary that is not ready receives no traffic.
- Plain Services cannot set an exact traffic weight.
- A stop condition is written before the canary starts.

<!-- astrona:playground:destroy -->
