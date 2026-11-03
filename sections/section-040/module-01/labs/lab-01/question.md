# Question

Solve this question on: `terminal`

Argo CD runs in `argocd` and Gitea runs in `gitea`. The repository `starfleet/fleet-config` holds `apps/scout` (a Deployment and a Service) and `apps/intruder` (a ConfigMap). Two Applications exist in the project `default`, which allows everything:

- `scout` deploys `apps/scout` to the namespace `starfleet`.
- `intruder` deploys `apps/intruder` to the namespace `vault`.

The repository URL used by the Applications is `http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git`. The Argo CD server address is `https://kubernetes.default.svc`.

1. Create an `AppProject` named `crew` in `argocd`. It must allow exactly one source repository (the URL above) and exactly one destination: the Argo CD server address with the namespace `starfleet`. It must allow no cluster-scoped kinds.

2. Move the Application `scout` into the project `crew`. It must stay `Synced` and `Healthy`.

3. Move the Application `intruder` into the project `crew`, without changing its destination. The project must now refuse it. Do not delete the Application.

`kubectl` already points at the cluster as the cluster administrator.

Check your work with `astrona submit`.
