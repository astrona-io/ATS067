# Canary Steps And Blue-Green With Argo Rollouts - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-067-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35) with the Argo Rollouts controller v1.10.0 in `argo-rollouts`. The namespace `starfleet` has the canary Rollout `scout` (4 replicas, steps 25, pause 20s, 50, pause 20s), the blue-green Rollout `shield` (4 replicas, manual promotion), their Services and a `curl` client. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-01/playground
astrona destroy ats-067-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, start scripts) |
| `bootstrap/01-install-rollouts.sh` | Installs the controller from a checksum-verified manifest |
| `bootstrap/02-start-playground.sh` | Creates the Rollouts and waits until they are Healthy |
| `manifests/starfleet.yaml` | Namespace, Services, Rollouts and the client |
| `docs/overview.md` | What the environment contains and ideas to try |
