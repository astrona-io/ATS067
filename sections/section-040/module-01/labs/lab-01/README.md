---
estimated_duration: 35m
---

# Lab: Fence Two Applications With An AppProject

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with Gitea, Argo CD and two Applications in the project `default`. `scout` deploys `apps/scout` to `starfleet`. `intruder` deploys a ConfigMap to the namespace `vault`, which nobody should deploy to. The project `crew` does not exist yet. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/module-01/labs/lab-01
astrona destroy ats-067-lab-040-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | Gitea, Argo CD, both Applications and the Deployment exist (passes before any change) |
| `validate-project-defined.sh` | The `AppProject` `crew` lists exactly the one repository, one destination (in-cluster, namespace `starfleet`) and no cluster-scoped kinds |
| `validate-scout-in-project.sh` | `scout` is in `crew`, `Synced`, `Healthy` and has no `InvalidSpecError` |
| `validate-intruder-blocked.sh` | `intruder` is in `crew`, its destination is still `vault` and it has the condition `InvalidSpecError` |
