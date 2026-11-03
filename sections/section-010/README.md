---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# Section 010: Deployment and Release Patterns

This section teaches you how a release moves from the old version to the new one without an outage, and how you prove that it worked or undo it. You will watch a Deployment replace pods, break a rollout on purpose and read why it stalls, roll back, and run blue-green and canary releases with plain Deployments and Services.

**Exam objective covered:** Deployment and Release Patterns

---

## What You Will Master

- Compute the pod limits of a rolling update from `maxSurge` and `maxUnavailable`, including the rounding of percentages.
- Explain how a Deployment uses one ReplicaSet per pod template and the `pod-template-hash` label.
- Predict what a failing readiness, liveness or startup probe does to a rollout.
- Use `minReadySeconds` and `progressDeadlineSeconds` and read the `Progressing` condition.
- Read the rollout history, roll back with `kubectl rollout undo`, and explain why a rollback does not undo data changes.
- Run a blue-green release with two Deployments and switch a Service selector.
- Run a canary release by replica ratio and compute its traffic share from the ready endpoints.
- Record evidence for a release in a ConfigMap that matches the live cluster.

---

## The Learning Path

### 1. Rolling Updates And Health Gates
*   **Module Reader:** **[Module 1: Rolling Updates And Health Gates](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-010/module-01/playground` - kind cluster. The namespace `starfleet` runs healthy Deployments of `ghcr.io/stefanprodan/podinfo` and a curl client. No update is in progress.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-01/playground
    ```
*   **Lab:** `sections/section-010/module-01/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-01/labs/lab-01
    astrona submit -c .
    ```

### 2. Blue-Green And Canary With Services
*   **Module Reader:** **[Module 2: Blue-Green And Canary With Services](./module-02/course.md)**
*   **Hands-on Playground:** `sections/section-010/module-02/playground` - kind cluster. Blue and green Deployments, a stable and a canary Deployment and their Services are ready to change.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-02/playground
    ```
*   **Lab:** `sections/section-010/module-02/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-02/labs/lab-01
    astrona submit -c .
    ```

### Section Capstone Challenge
*   **Comprehensive Challenge:** Deployment and Release Patterns Capstone - `sections/section-010/capstone/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Repair a stuck rolling update, roll back an update to an image that cannot be pulled, switch a blue-green Service to green and record the result in a ConfigMap. The grader checks live cluster state.

### Knowledge Check
*   **Quiz:** 10 questions in `sections/section-010/quiz.yaml`. The pass score is 70 percent.
