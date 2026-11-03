---
draft: true
exam_objectives:
  - Architecture Patterns (in-cluster and external reconciler, state store management, etc.)
---
# Section 040: Architecture Patterns

This section teaches you where a GitOps reconciler can run, what each placement needs in credentials and what breaks when a part fails, how an `AppProject` fences an application, and how a repository is laid out so that environments share manifests. You will fence applications with projects, promote a change by a commit and undo a faulty commit with `git revert`.

**Exam objective covered:** Architecture Patterns (in-cluster and external reconciler, state store management, etc.)

---

## What You Will Master

- Compare a reconciler inside the cluster, one hub for many clusters and one reconciler per cluster.
- Say which credentials each placement needs and which side opens the connection.
- Name the failure domains of Argo CD and predict what keeps running when one of them stops.
- Write an `AppProject` with `sourceRepos`, `destinations` and a cluster resource allow list, and read the `InvalidSpecError` condition.
- Describe repository and cluster credentials as Secrets and say why they need access control.
- Build an environment from a Kustomize base and an overlay, and render it with `kubectl kustomize`.
- Compare folders, branches and repositories per environment.
- Promote by a commit that touches only the target overlay, and undo a commit with `git revert` without rewriting history.
- Say what belongs in Git as desired state, what must stay out, and how a cluster is rebuilt from Git.

---

## The Learning Path

### 1. Agent Placement, Credentials And Failure Domains
*   **Module Reader:** **[Module 1: Agent Placement, Credentials And Failure Domains](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-040/module-01/playground` - kind cluster with Gitea, Argo CD, the `AppProject` `crew`, a repository Secret and two Applications (one allowed, one refused).
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/module-01/playground
    ```
*   **Lab:** `sections/section-040/module-01/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/module-01/labs/lab-01
    astrona submit -c .
    ```

### 2. Repository Layout And State Store Management
*   **Module Reader:** **[Module 2: Repository Layout And State Store Management](./module-02/course.md)**
*   **Hands-on Playground:** `sections/section-040/module-02/playground` - kind cluster with Gitea, Argo CD, a Kustomize base with the overlays `dev` and `prod`, and the Applications `scout-dev` and `scout-prod`.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/module-02/playground
    ```
*   **Lab:** `sections/section-040/module-02/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/module-02/labs/lab-01
    astrona submit -c .
    ```

### Section Capstone Challenge
*   **Comprehensive Challenge:** Two Environments With Their Own Projects, Promotion And Revert - `sections/section-040/capstone/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Fence two environments with their own projects, revert a faulty production commit, promote a tested value by a commit to the production overlay only, and record the release in a ConfigMap. The grader checks live cluster state and the Git history.

### Knowledge Check
*   **Quiz:** 13 questions in `sections/section-040/quiz.yaml`. The pass score is 70 percent.
