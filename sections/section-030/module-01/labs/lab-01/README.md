---
estimated_duration: 35m
---

# Lab: Make Git The Only Way To Change An Application

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with Gitea, Argo CD and the Application `scout`, which has automated sync but no prune and no self-heal. The repository `starfleet/fleet-config` holds a Deployment with 2 replicas, a Service and the ConfigMap `old-flags`. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-067-lab-030-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | Gitea, Argo CD, the Application and the Deployment exist (passes before any change) |
| `validate-sync-policy.sh` | `automated` with `prune: true` and `selfHeal: true`, and the path is unchanged |
| `validate-git-change-applied.sh` | `main` holds `replicas: 3` and no `old-flags.yaml`, the Application is `Synced` at the head of `main`, the live Deployment has 3 replicas and `old-flags` is gone |
| `validate-sync-record.sh` | The ConfigMap `sync-record` equals the Application revision, the live replicas and a UTC time |
