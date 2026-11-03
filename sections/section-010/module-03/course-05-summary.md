---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# Summary

The Recreate strategy stops every pod of the old version before it creates the first pod of the new version. It needs no spare capacity and never runs two versions together, and it causes a period without ready pods. It suits applications that hold an exclusive lock or a volume that one pod can mount, and it does not suit a service with an availability target. A Recreate Deployment has no `rollingUpdate` section, and a rollback causes a second gap.

A feature flag separates deploying code from releasing a feature. The code ships turned off and a configuration change turns it on. A ConfigMap key copied to an environment variable changes only when the pod is replaced. A mounted ConfigMap file changes without a restart after the kubelet refreshes it, and only helps when the application reads the file again. A flag kept in Git has an audit trail and is slow to change. A flag kept in a service is fast and needs its own record of changes.

A canary release tests the safety of a version on a random share of traffic. An A/B release compares two versions for groups of users that stay apart. A Service routes by connection and ignores headers, cookies and users, so routing by request needs an ingress controller, a gateway or a service mesh. Shadow traffic sends a copy of each request to a new version and discards its answers, which removes user exposure and doubles load and repeats side effects.

The choice of strategy follows from whether two versions can run together, the spare capacity, the cost of a defect, the speed of reversal and what the team can measure. Combined patterns, such as a dark launch, a rolling update and a flagged canary, answer one question at each step.

Key facts:

- Recreate scales the old ReplicaSet to 0 and waits before the new one starts.
- `rollingUpdate` must be removed when the type changes to Recreate.
- An environment variable from a ConfigMap changes only in new pods.
- A Service does not read headers, cookies or paths.
- A mirrored request has the same side effects as a real request.

<!-- astrona:playground:destroy -->
