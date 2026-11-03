---
estimated_duration: 25m
---

# Lab: Fix A Stuck Rollout And Roll Back A Bad Release

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with two Deployments that were updated badly: `scout` has a wrong readiness probe path and risky rollout settings, and `probe` uses an image that cannot be pulled. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-067-lab-010-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | The three Deployments exist with their replica counts (passes before any change) |
| `validate-scout-rollout-complete.sh` | `scout` has the new image, `version-2`, the correct probe path and 3 ready pods that are not terminating |
| `validate-scout-rollout-settings.sh` | `maxSurge` 1, `maxUnavailable` 0, `minReadySeconds` of 5 or more and a progress deadline of 180 seconds or less |
| `validate-probe-rolled-back.sh` | `probe` runs the good image at revision 3 or later with ready pods and no pod with the broken image |
| `validate-release-record.sh` | The ConfigMap `release-record` equals the live revisions and has a UTC time |
