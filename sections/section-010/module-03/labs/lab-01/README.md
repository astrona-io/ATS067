---
estimated_duration: 20m
---

# Lab: Recreate A Deployment And Turn On A Feature Flag

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with a `ledger` Deployment on the RollingUpdate strategy, a feature flag that is off in the ConfigMap `scout-flags` and a `flagcheck` pod that reads the flag. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-03/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-03/labs/lab-01
astrona destroy ats-067-lab-010-03
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | `ledger` and `flagcheck` exist and are available (passes before any change) |
| `validate-ledger-recreate.sh` | `ledger` has type Recreate, no rollingUpdate section, image tag 6.14.0 and 2 ready replicas |
| `validate-flag-live.sh` | The flag is `on` in the ConfigMap, in the file and in the environment of the running pod |
| `validate-release-evidence.sh` | The ConfigMap `release-evidence` equals the live strategy, image tag and flag |
