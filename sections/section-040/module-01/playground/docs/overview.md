# Overview: Agent Placement, Credentials And Failure Domains (Playground)

This is a **playground**, not a lab. It starts a cluster with Argo CD and a Git server, then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.
- Gitea in the namespace `gitea` (Service `gitea-http`, port 3000). The user is `platform` and the password is `starfleet-gitops`. The repository `starfleet/fleet-config` is public and holds `apps/scout` (a Deployment with 2 replicas and a Service) and `apps/intruder` (a ConfigMap without a namespace).
- Argo CD v3.5.4 in `argocd`. Dex and the notifications controller are scaled to zero.
- The `AppProject` `crew`. It allows one repository, one destination (the in-cluster server and the namespace `starfleet`) and no cluster-scoped kinds.
- The Secret `repo-fleet`, a repository credential in the form that Argo CD reads.
- The Application `scout` (project `crew`, automated sync with prune and self-heal) deploys `apps/scout` to `starfleet`.
- The Application `outsider` (project `crew`) deploys `apps/intruder` to the namespace `vault`, which the project does not allow.

## Look at the limits

```sh
kubectl -n argocd get appproject crew -o yaml
kubectl -n argocd get application
kubectl -n argocd get application outsider -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.message}{"\n"}{end}'
```

## Practice tasks

- Change the destination namespace of `outsider` to `starfleet`. Read what happens to the condition and the sync.
- Add `namespaceResourceWhitelist` with only `Service` to the project and refresh `scout`. Read the error.
- Add a cluster-scoped kind (a `Namespace`) to a new folder in the repository and watch the project refuse it.
- Scale the application controller to zero (`kubectl -n argocd scale statefulset argocd-application-controller --replicas=0`). Check that the pods in `starfleet` still run. Scale the Deployment `scout` by hand and note that nothing reverts it. Scale the controller back to 1.
- Scale `argocd-repo-server` to zero and read the error that an Application shows after a hard refresh. Scale it back.
- List the Secrets with the label `argocd.argoproj.io/secret-type` and note that the in-cluster destination has no cluster Secret.
