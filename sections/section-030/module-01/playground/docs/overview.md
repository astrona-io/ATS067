# Overview: Pull-Based Reconciliation With Argo CD (Playground)

This is a **playground**, not a lab. It starts a cluster with Argo CD and a Git server, then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.
- Gitea in the namespace `gitea` (Service `gitea-http`, port 3000). The user is `platform` and the password is `starfleet-gitops`. The repository `starfleet/fleet-config` is public and holds `apps/scout/deployment.yaml`, `service.yaml` and `old-flags.yaml`.
- Argo CD v3.5.4 in `argocd`. Dex and the notifications controller are scaled to zero.
- The Application `scout` in `argocd`. It deploys `apps/scout` of the repository to the namespace `starfleet` with `automated: {}`: no prune and no self-heal.

## Work with the repository

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/fleet-config.git
```

Commit and push to `main`. Argo CD finds the commit on its next refresh (every 3 minutes by default) or when you request a refresh:

```sh
kubectl -n argocd annotate application scout argocd.argoproj.io/refresh=hard --overwrite
```

## Practice tasks

- Read `status.sync`, `status.health` and `status.resources` of the Application with `kubectl get application scout -o yaml`.
- Scale the Deployment by hand and watch that nothing reverts it. Then add `selfHeal: true` and repeat.
- Delete `old-flags.yaml` from Git and watch the ConfigMap stay. Then add `prune: true`.
- Push a commit with a wrong image and read the health of the Application.
- Set `targetRevision` to a missing branch and read `status.conditions`.
- Remove the `automated` block and make a change in Git. Start a sync by writing an `operation` into the Application.
