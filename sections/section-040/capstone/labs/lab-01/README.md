---
estimated_duration: 55m
---

# Lab: Two Environments With Their Own Projects, Promotion And Revert

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with Gitea, Argo CD and two Applications, `scout-dev` and `scout-prod`, in the project `default`. They deploy the overlays of one Kustomize base. The history of `main` has two more commits after the first one: `dev: message release-2` (tested in `dev`) and `prod: bump podinfo to 6.99.0` (the image tag does not exist). The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-067-capstone-040
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | Gitea, Argo CD, both Applications and both Deployments exist (passes before any change) |
| `validate-projects-defined.sh` | `dev-env` and `prod-env` each list exactly the one repository, one destination (in-cluster, their own namespace) and no cluster-scoped kinds |
| `validate-apps-in-projects.sh` | `scout-dev` is in `dev-env`, `scout-prod` is in `prod-env`, and neither has `InvalidSpecError` |
| `validate-git-release.sh` | The image bump is reverted (a `This reverts commit` commit exists and the bump is still in history), `overlays/prod` holds `release-2`, and `overlays/dev` and the base are unchanged |
| `validate-environments-reconciled.sh` | Both Applications are `Synced` and `Healthy` at the head of `main` and run `release-2` with the image `6.15.0` |
| `validate-release-record.sh` | The ConfigMap `release-record` in `scout-prod` equals the Application revision and the live message |
