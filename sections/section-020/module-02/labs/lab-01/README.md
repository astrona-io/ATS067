---
estimated_duration: 30m
---

# Lab: Gate A Canary With An AnalysisTemplate And Survive A Bad Release

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with the Argo Rollouts controller, `go-httpbin` in the namespace `analysis` and a canary Rollout `scout` at version 1. No AnalysisTemplate exists. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-067-lab-020-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | `scout`, `shuttle` and `httpbin` exist (passes before any change) |
| `validate-quality-gate-template.sh` | The AnalysisTemplate `quality-gate` has the argument, the web metric, the condition, the interval, the count and the failure limit |
| `validate-bad-release-aborted.sh` | A Failed AnalysisRun of `scout` with `score=40` exists, the Rollout uses the template and no `version-bad` pod runs |
| `validate-good-release-complete.sh` | `scout` is Healthy on `version-3` with `score=95`, a Successful run exists and it came after the failed one |
