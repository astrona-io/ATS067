---
estimated_duration: 25m
---

# Lab: Stage A Canary And A Blue-Green Release With Argo Rollouts

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with the Argo Rollouts controller, a canary Rollout `scout` that releases in a single step, and a blue-green Rollout `shield` that promotes by itself. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-067-lab-020-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | The Rollouts and the client exist with their replica counts (passes before any change) |
| `validate-scout-canary-steps.sh` | `scout` has the steps 25, pause, 50, pause, walked all 4 steps, is Healthy and 4 pods run version-2 |
| `validate-shield-staged.sh` | `shield` is Paused with `autoPromotionEnabled` false and 1 preview pod; active reaches 4 version-1 pods |
| `validate-rollout-record.sh` | The ConfigMap `rollout-record` equals the live stable ReplicaSet hash and active selector hash |
