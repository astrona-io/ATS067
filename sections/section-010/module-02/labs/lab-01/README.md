---
estimated_duration: 20m
---

# Lab: Switch A Blue-Green Release And Set A 25 Percent Canary

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with a blue and a green Deployment behind the Service `scout` (which serves blue) and a stable and a canary Deployment for `probe` (the canary has 0 replicas and the Service selector excludes it). The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-067-lab-010-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | All Deployments exist with their replica counts (passes before any change) |
| `validate-active-track-green.sh` | The ready endpoints of `scout` are exactly the 2 green pods and `scout-blue` keeps 2 available replicas |
| `validate-canary-share.sh` | The ready endpoints of `probe` are 3 stable and 1 canary pod |
| `validate-release-evidence.sh` | The ConfigMap `release-evidence` equals the live track, the live canary percent and has a UTC time |
