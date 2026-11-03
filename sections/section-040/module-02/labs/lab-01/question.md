# Question

Solve this question on: `terminal`

Argo CD runs in `argocd` and Gitea runs in `gitea`. The repository `starfleet/fleet-config` on the branch `main` holds a Kustomize base `base/scout` and two overlays: `overlays/dev` and `overlays/prod`. The Applications `scout-dev` and `scout-prod` deploy the overlays to the namespaces `scout-dev` and `scout-prod` with automated sync, prune and self-heal.

The history of `main` after the first commit has two commits:

- `dev: message release-2` changed the message in `overlays/dev`. It was tested in `dev`.
- `prod: set replicas to 0` set the replica count of `overlays/prod` to 0. It is faulty and the production Deployment now has no pods.

Reach Gitea with a port-forward to `svc/gitea-http` (port 3000). The user is `platform` and the password is `starfleet-gitops`.

1. Undo the faulty commit in a way that keeps it in the history. Do not rewrite history and do not force-push.

2. Promote the message `release-2` to production. Change only the production overlay. Do not edit `base` and do not edit `overlays/dev`. Production must keep 2 replicas.

3. Push to `main` and wait until both Applications are `Synced` and `Healthy` at the head of `main`. `dev` must keep 1 replica.

`kubectl` already points at the cluster as the cluster administrator.

Check your work with `astrona submit`.
