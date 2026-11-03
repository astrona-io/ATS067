---
estimated_duration: 50m
---

# Lab: Reconcile From Git And Trigger From An Event

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with Gitea, Argo CD and Argo Events. The Application `scout` has manual sync and was synced once. Someone then scaled the live Deployment to 6 replicas, while Git says 2. The ConfigMap `deploy-state` and the ServiceAccount `sensor-runner` exist, but there is no EventSource and no Sensor. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-067-capstone-030
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | Gitea, Argo CD, Argo Events, the client and `deploy-state` exist (passes before any change) |
| `validate-drift-healed.sh` | `automated` with `prune` and `selfHeal`, and the live replicas equal the value in Git |
| `validate-git-release-applied.sh` | `main` sets `version-2`, the Application is `Synced` at the head of `main` and the live Deployment has `version-2` |
| `validate-event-path-defined.sh` | `ref-hook` (webhook `release`, `/release`, POST, Service) and `ref-sensor` (dependency, `sensor-runner`, `patch` trigger on `deploy-state` with both parameters) exist |
| `validate-event-recorded.sh` | `deploy-state` holds `service: scout` and the head commit of `main`, and no generated copies exist |
