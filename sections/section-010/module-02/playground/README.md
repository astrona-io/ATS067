# Blue-Green And Canary With Services - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-067-playground-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35) with a blue and a green `scout` behind two Services, a stable and a canary `probe` behind one Service, and a `curl` client in `starfleet`. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-02/playground
astrona destroy ats-067-playground-010-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `manifests/starfleet.yaml` | The namespace, the Deployments and Services and the client |
| `docs/overview.md` | What the environment contains and ideas to try |
