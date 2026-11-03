# Question

Solve this question on: `terminal`

Argo CD runs in `argocd` and Gitea runs in `gitea`. The repository `starfleet/fleet-config` on the branch `main` holds a Kustomize base `base/scout` and the overlays `overlays/dev` and `overlays/prod`. The Applications `scout-dev` and `scout-prod` deploy the overlays to the namespaces `scout-dev` and `scout-prod`. Both are in the project `default`, which allows everything. They have automated sync with prune and self-heal.

The history of `main` after the first commit has two commits:

- `dev: message release-2` changed the message in `overlays/dev`. It was tested in `dev`.
- `prod: bump podinfo to 6.99.0` added an image tag to `overlays/prod`. The tag does not exist and the production Deployment cannot pull it.

The repository URL used by the Applications is `http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git`. The Argo CD server address is `https://kubernetes.default.svc`. Reach Gitea with a port-forward to `svc/gitea-http` (port 3000). The user is `platform` and the password is `starfleet-gitops`. Do not delete the Applications.

1. Create two `AppProject` objects in `argocd`: `dev-env` and `prod-env`. Each allows exactly one source repository (the URL above), exactly one destination (the Argo CD server address with the namespace of its own environment, `scout-dev` or `scout-prod`) and no cluster-scoped kinds. Move `scout-dev` into `dev-env` and `scout-prod` into `prod-env`.

2. Undo the faulty production commit in a way that keeps it in the history. Do not rewrite history and do not force-push.

3. Promote the message `release-2` to production. Change only the production overlay. Do not edit `base` and do not edit `overlays/dev`.

4. Push to `main` and wait until both Applications are `Synced` and `Healthy` at the head of `main`.

5. Create the ConfigMap `release-record` in the namespace `scout-prod` with the keys `prod-revision` (the revision that `scout-prod` was synced to) and `prod-message` (the message that the production Deployment runs).

`kubectl` already points at the cluster as the cluster administrator.

Check your work with `astrona submit`.
