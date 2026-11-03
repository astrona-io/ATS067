# Rolling Updates And Health Gates - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-067-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the Deployment `scout` (4 replicas, rolling update with `maxSurge: 1` and `maxUnavailable: 0`), its Service and a `curl` client in `starfleet`. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-01/playground
astrona destroy ats-067-playground-010-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | The namespace, the `scout` Deployment and Service and the `shuttle` client |
| `docs/overview.md` | What the environment contains and ideas to try |
