# Event-Driven Triggers With Argo Events - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-067-playground-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35) with Argo Events v1.9.11 and a JetStream EventBus in `argo-events`, the webhook EventSource `fleet-hook`, the Sensor `fleet-sensor` with a create trigger, and a `curl` client in `starfleet`. Nothing to submit.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-02/playground
astrona destroy ats-067-playground-030-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/03-install-argo-events.sh` | Installs the controller and the EventBus |
| `bootstrap/02-start-playground.sh` | Creates the EventSource, the Sensor and the client |
| `manifests/eventbus.yaml` | The EventBus |
| `manifests/starfleet.yaml` | Namespace, client, permissions, EventSource and Sensor |
| `docs/overview.md` | What the environment contains and ideas to try |
