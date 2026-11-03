# Question

Solve this question on: `terminal`

Argo CD runs in `argocd` and Gitea runs in `gitea`. The repository `starfleet/fleet-config` on the branch `main` holds the folder `apps/scout` with a Deployment (2 replicas), a Service and the ConfigMap `old-flags`. The Application `scout` deploys that folder to the namespace `starfleet`. It has automated sync, but no prune and no self-heal.

Reach Gitea with a port-forward to `svc/gitea-http` (port 3000). The user is `platform` and the password is `starfleet-gitops`. Do not delete the Application.

1. Change the Application `scout` so that automated sync deletes objects that were removed from Git and reverts live changes. Keep the source path.

2. In the repository, make one commit on `main` that sets the Deployment to 3 replicas and deletes `apps/scout/old-flags.yaml`. Push it. Wait until the Application is `Synced` at that commit, the live Deployment has 3 replicas and the ConfigMap `old-flags` is gone from the cluster. Use the refresh annotation instead of waiting for the timer if you like.

3. Create a ConfigMap named `sync-record` in `starfleet` with these keys:
   - `synced-revision`: `status.sync.revision` of the Application
   - `replicas`: the number of replicas of the live Deployment `scout`
   - `observed-at`: the current UTC time like `2026-11-03T10:15:00Z`

`kubectl` already points at the cluster as the cluster administrator.

Check your work with `astrona submit`.
