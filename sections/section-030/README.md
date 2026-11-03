---
draft: true
exam_objectives:
  - Pull vs. Event-driven
---
# Section 030: Pull vs. Event-driven

This section teaches you how a cluster takes its state from Git without anyone pushing to it, and how an event can start work in the cluster safely. You will let Argo CD compare Git with live objects, choose a sync policy, and then connect a webhook to a Sensor that records a release.

**Exam objective covered:** Pull vs. Event-driven

---

## What You Will Master

- Explain the pull loop: repository, desired state, live state, comparison and sync.
- Read `status.sync.status`, `status.health.status` and `status.sync.revision` of an Application.
- Tell manual sync from `automated` sync and say what `prune` and `selfHeal` each add.
- Use `syncOptions` such as `CreateNamespace=true` and force a fetch with the hard refresh annotation.
- Explain the reconciliation interval and why a webhook shortens the delay.
- Name the parts of Argo Events: EventSource, EventBus and Sensor.
- Read the shape of a webhook event (`header` and `body`) and address a value with `dataKey`.
- Write a Sensor with a dependency filter and a Kubernetes trigger.
- Explain at-least-once delivery and choose a `patch` trigger so that a repeated event changes nothing.

---

## The Learning Path

### 1. Pull-Based Reconciliation With Argo CD
*   **Module Reader:** **[Module 1: Pull-Based Reconciliation With Argo CD](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-030/module-01/playground` - kind cluster with Gitea (a repository `starfleet/fleet-config`) and Argo CD. The Application `scout` deploys `apps/scout`.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-01/playground
    ```
*   **Lab:** `sections/section-030/module-01/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-01/labs/lab-01
    astrona submit -c .
    ```

### 2. Event-Driven Triggers With Argo Events
*   **Module Reader:** **[Module 2: Event-Driven Triggers With Argo Events](./module-02/course.md)**
*   **Hands-on Playground:** `sections/section-030/module-02/playground` - kind cluster with Argo Events v1.9.11, a JetStream EventBus, a webhook EventSource, a Sensor and a `curl` client.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-02/playground
    ```
*   **Lab:** `sections/section-030/module-02/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-02/labs/lab-01
    astrona submit -c .
    ```

### Section Capstone Challenge
*   **Comprehensive Challenge:** Reconcile From Git And Trigger From An Event - `sections/section-030/capstone/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Heal a drifted Deployment with automated sync, release a change through a Git commit, then build an EventSource and a Sensor that record the commit in a ConfigMap, and send the event twice. The grader checks live cluster state and the Git history.

### Knowledge Check
*   **Quiz:** 10 questions in `sections/section-030/quiz.yaml`. The pass score is 70 percent.
