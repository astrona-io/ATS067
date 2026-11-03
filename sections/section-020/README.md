---
draft: true
exam_objectives:
  - Progressive Delivery Patterns
---
# Section 020: Progressive Delivery Patterns

This section teaches you how Argo Rollouts releases a new version in steps and lets measurements decide whether the release continues. You will run canary and blue-green releases, read the status fields that show what the controller decided, and let an AnalysisTemplate abort a bad version.

**Exam objective covered:** Progressive Delivery Patterns

---

## What You Will Master

- Explain what a `Rollout` replaces and how the controller keeps one ReplicaSet per pod template.
- Write canary steps with `setWeight` and `pause`, and tell a timed pause from an indefinite one.
- Compute the replica split of a canary step when no traffic router is used.
- Read `status.stableRS`, `status.currentPodHash`, `status.currentStepIndex` and `status.phase`.
- Run a blue-green release with an active and a preview Service, and hold a version in the preview with `autoPromotionEnabled: false`.
- Explain `scaleDownDelaySeconds`, `previewReplicaCount` and the pre- and post-promotion analysis fields.
- Write an `AnalysisTemplate` with the web provider, a `jsonPath`, a `successCondition`, an interval, a count and a `failureLimit`.
- Read an `AnalysisRun`, tell its phases apart and explain why a failed run aborts a release and keeps the stable version.

---

## The Learning Path

### 1. Canary Steps And Blue-Green With Argo Rollouts
*   **Module Reader:** **[Module 1: Canary Steps And Blue-Green With Argo Rollouts](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-020/module-01/playground` - kind cluster with the Argo Rollouts controller v1.10.0. A canary Rollout and a blue-green Rollout run version 1.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-01/playground
    ```
*   **Lab:** `sections/section-020/module-01/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-01/labs/lab-01
    astrona submit -c .
    ```

### 2. AnalysisTemplate And AnalysisRun Decisions
*   **Module Reader:** **[Module 2: AnalysisTemplate And AnalysisRun Decisions](./module-02/course.md)**
*   **Hands-on Playground:** `sections/section-020/module-02/playground` - kind cluster with the controller, `go-httpbin`, the template `quality-gate` and a canary Rollout without analysis.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-02/playground
    ```
*   **Lab:** `sections/section-020/module-02/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-02/labs/lab-01
    astrona submit -c .
    ```

### Section Capstone Challenge
*   **Comprehensive Challenge:** Progressive Delivery Capstone - `sections/section-020/capstone/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Find out why a good canary release fails its analysis, repair the AnalysisTemplate, release again, gate a blue-green promotion with a failing score and record the result in a ConfigMap. The grader checks live cluster state.

### Knowledge Check
*   **Quiz:** 10 questions in `sections/section-020/quiz.yaml`. The pass score is 70 percent.
