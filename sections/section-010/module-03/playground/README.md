# Recreate, Feature Flags And Traffic Experiments - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-067-playground-010-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35) with a Recreate Deployment, a feature flag in a ConfigMap, two `scout` versions behind three Services and a `curl` client in `starfleet`. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-010/module-03/playground
astrona destroy ats-067-playground-010-03
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `manifests/starfleet.yaml` | The namespace, the Deployments, the Services and the ConfigMap |
| `docs/overview.md` | What the environment contains and ideas to try |
