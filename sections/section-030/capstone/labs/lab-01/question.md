# Question

Solve this question on: `terminal`

Argo CD runs in `argocd`, Gitea in `gitea` and Argo Events in `argo-events`. The repository `starfleet/fleet-config` on `main` holds `apps/scout` (a Deployment with 2 replicas and the message `version-1`, and a Service). The Application `scout` deploys that folder to `starfleet` with manual sync. Someone scaled the live Deployment to 6 replicas by hand. In `starfleet`, a `curl` client runs as `shuttle`, the ConfigMap `deploy-state` holds `service: none` and `ref: none`, and the ServiceAccount `sensor-runner` in `argo-events` may create, get, patch and update ConfigMaps in `starfleet`.

Reach Gitea with a port-forward to `svc/gitea-http` (port 3000). The user is `platform` and the password is `starfleet-gitops`. Do not delete the Application, the EventBus or `deploy-state`.

1. Change the Application so that it syncs by itself, deletes objects that were removed from Git and reverts live changes. The live Deployment must return to the replica count in Git.

2. In the repository, commit one change to `main` that sets the message (`PODINFO_UI_MESSAGE`) to `version-2`. Wait until the Application is `Synced` at that commit and the live Deployment has the new message.

3. Create an `EventSource` named `ref-hook` in `argo-events` with a webhook entry named `release` on port `12000`, endpoint `/release` and method `POST`, and a `service` that exposes port 12000. Create a `Sensor` named `ref-sensor` in `argo-events` that runs as `sensor-runner`, depends on the event `release` of `ref-hook` and has a Kubernetes trigger with the operation `patch` on the ConfigMap `deploy-state` in `starfleet`. The trigger copies `body.service` to `data.service` and `body.ref` to `data.ref`.

4. From the client pod, send the event `{"service":"scout","ref":"<commit>"}` to the event source twice, where `<commit>` is the commit hash of the head of `main`. Wait until `deploy-state` holds `service: scout` and `ref` equal to that hash. The sensor must not create new ConfigMaps.

`kubectl` already points at the cluster as the cluster administrator.

Check your work with `astrona submit`.
