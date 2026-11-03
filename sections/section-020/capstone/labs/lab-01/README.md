---
estimated_duration: 40m
---

# Lab: Repair And Release With Automated Analysis

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with the canary Rollout `scout` (version 1, background analysis with the template `quality-gate`, whose threshold is too high), the blue-green Rollout `shield` (version 1, no analysis) and `go-httpbin` as the measured endpoint. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-067-capstone-020
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | Both Rollouts, the Services, the client and go-httpbin exist (passes before any change) |
| `validate-template-repaired.sh` | `quality-gate` keeps its metric and its threshold is above 40 and not above 95 |
| `validate-scout-released.sh` | `scout` is Healthy on `version-3`, 4 ready pods, `stableRS` equals `currentPodHash` and a Successful run with `score=95` exists |
| `validate-shield-gated.sh` | `shield` has `prePromotionAnalysis` with `quality-gate`, a Failed run with `score=40` exists and the Service `shield` selects the stable ReplicaSet |
| `validate-analysis-record.sh` | The ConfigMap `analysis-record` equals the live stable ReplicaSets, a Failed run of `shield` and a UTC time |
