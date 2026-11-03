---
estimated_duration: 35m
---

# Lab: Build A Safe Event Path From A Webhook To A Patch

Graded lab. **Status: UNTESTED.** It was built without booting the lab; run `astrona test -c .` before relying on it.

The cluster starts with Argo Events, a ready EventBus, a `curl` client in `starfleet`, the ServiceAccount `sensor-runner` (with a Role for ConfigMaps in `starfleet`) and the ConfigMap `deploy-state`. There is no EventSource and no Sensor. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-067-lab-030-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-workloads-running.sh` | The controller, the EventBus, the client and `deploy-state` exist (passes before any change) |
| `validate-eventsource-defined.sh` | `fleet-hook` has the webhook entry `deploy` (port 12000, `/deploy`, POST) and the Service `fleet-hook-eventsource-svc` exists |
| `validate-sensor-defined.sh` | `fleet-sensor` depends on `fleet-hook/deploy`, filters `body.ref` on `main`, uses `sensor-runner` and has a `patch` trigger on `deploy-state` with both parameters |
| `validate-event-applied.sh` | `deploy-state` holds `service: scout` and `ref: main`, and no `deploy-event-*` ConfigMaps exist |
