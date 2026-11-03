---
estimated_duration: 30m
---

# Capstone Lab: Repair And Release A Starfleet Workload Set

Graded capstone lab for section 010. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with `warp` (a stuck rolling update with a wrong readiness probe path and risky settings), `impulse` (an update to an image that cannot be pulled) and `shield` (a blue-green pair behind a Service that still serves blue). The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-067-capstone-010
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | All Deployments exist with their replica counts (passes before any change) |
| `validate-warp-rollout-complete.sh` | `warp` has the new image, `version-2`, the correct probe path and 3 ready pods |
| `validate-warp-rollout-settings.sh` | `maxSurge` 1, `maxUnavailable` 0, `minReadySeconds` of 5 or more and a deadline of 180 seconds or less |
| `validate-impulse-rolled-back.sh` | `impulse` runs the good image at revision 3 or later with ready pods |
| `validate-shield-switched.sh` | The ready endpoints of `shield` are the 2 green pods and `shield-blue` keeps 2 available replicas |
| `validate-release-record.sh` | The ConfigMap `release-record` equals the live revisions, the live track and has a UTC time |
