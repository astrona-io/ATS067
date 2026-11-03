# Overview: Repository Layout And State Store Management (Playground)

This is a **playground**, not a lab. It starts a cluster with Argo CD and a Git server, then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.
- Gitea in the namespace `gitea` (Service `gitea-http`, port 3000). The user is `platform` and the password is `starfleet-gitops`. The repository `starfleet/fleet-config` is public.
- The repository holds `base/scout` (a Deployment and a Service without a namespace, with the message `base`) and the overlays `overlays/dev` (namespace `scout-dev`, 1 replica, message `release-1`) and `overlays/prod` (namespace `scout-prod`, 2 replicas, message `release-1`).
- Argo CD v3.5.4 in `argocd`. Dex and the notifications controller are scaled to zero.
- The Applications `scout-dev` and `scout-prod` deploy the two overlays with automated sync, prune and self-heal.

## Work with the repository

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/fleet-config.git
cd fleet-config
kubectl kustomize overlays/prod
```

Request a refresh after a push instead of waiting for the timer:

```sh
kubectl -n argocd annotate application scout-prod argocd.argoproj.io/refresh=hard --overwrite
```

## Practice tasks

- Render both overlays with `kubectl kustomize` and compare them with `diff`.
- Change the message in `overlays/dev`, push and read `status.sync.revision` of `scout-dev`.
- Promote the same value to `overlays/prod` in a second commit.
- Change `base/scout/deployment.yaml` (for example the memory limit) and watch both environments update.
- Make a bad commit (set the prod replica count to 0), then undo it with `git revert --no-edit HEAD` and read the history.
- Edit `scout-prod` by hand with `kubectl scale` and watch self-heal revert it.
- Add an `images` entry to an overlay and render it.
