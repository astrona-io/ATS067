---
estimated_duration: 40m
---

# Lab: Promote By Commit And Undo With Git Revert

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with Gitea, Argo CD and two Applications, `scout-dev` and `scout-prod`, which deploy the overlays of one Kustomize base. After the first commit, the history has two more commits: `dev: message release-2` and `prod: set replicas to 0`. The second one is faulty and was already applied. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/module-02/labs/lab-01
astrona destroy ats-067-lab-040-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | Gitea, Argo CD, both Applications and both Deployments exist (passes before any change) |
| `validate-revert-in-history.sh` | The commit `prod: set replicas to 0` is still in the history of `main` and a commit with `This reverts commit <hash>` exists |
| `validate-prod-promoted.sh` | On `main`, `overlays/prod` holds `count: 2` and `release-2`, `overlays/dev` is unchanged and the base is unchanged |
| `validate-environments-reconciled.sh` | Both Applications are `Synced` and `Healthy` at the head of `main` and the live Deployments match (dev 1 replica, prod 2 replicas, both `release-2`) |
