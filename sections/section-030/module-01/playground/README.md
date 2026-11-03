# Pull-Based Reconciliation With Argo CD - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-067-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35) with Gitea in `gitea`, Argo CD v3.5.4 in `argocd`, the repository `starfleet/fleet-config` and the Application `scout`, which has automated sync without prune and self-heal. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-01/playground
astrona destroy ats-067-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/01-install-gitea.sh` | Starts Gitea and creates the user `platform` |
| `bootstrap/02-install-argocd.sh` | Installs Argo CD |
| `bootstrap/03-start-playground.sh` | Seeds the repository and creates the Application |
| `bootstrap/seed-repo.sh` | Helper that pushes a folder to a Gitea repository |
| `repo/` | The content of the repository `fleet-config` |
| `manifests/` | The Gitea manifest and the Application |
| `docs/overview.md` | What the environment contains and ideas to try |
