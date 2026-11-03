# AnalysisTemplate And AnalysisRun Decisions - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-067-playground-020-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35) with the Argo Rollouts controller v1.10.0 in `argo-rollouts`, `go-httpbin` in `analysis`, the AnalysisTemplate `quality-gate`, the canary Rollout `scout` at version 1 and a `curl` client in `starfleet`. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-020/module-02/playground
astrona destroy ats-067-playground-020-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/01-install-rollouts.sh` | Installs the controller from a checksum-verified manifest |
| `bootstrap/02-start-playground.sh` | Creates go-httpbin, the template and the Rollout |
| `manifests/starfleet.yaml` | The namespaces, go-httpbin, the template, the Services, the Rollout and the client |
| `docs/overview.md` | What the environment contains and ideas to try |
