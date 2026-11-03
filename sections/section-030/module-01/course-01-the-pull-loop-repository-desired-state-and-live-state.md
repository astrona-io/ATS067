---
draft: true
exam_objectives:
  - Pull vs. Event-driven
---
# The Pull Loop: Repository, Desired State And Live State

In a pull-based model, a component inside the cluster reads the desired state from Git and changes the cluster to match. Nothing outside the cluster needs a credential for the cluster API. This part shows the pieces that do the work in Argo CD and the order in which they act.

## Push and pull differ in who holds the credential

In a push model, a pipeline runs after a commit and calls the cluster API, for example with `kubectl apply`. The pipeline must hold a credential for the cluster and must be able to reach the API server over the network. The cluster only changes when the pipeline runs, so a change made by hand stays until the next run.

In a pull model, the agent runs in the cluster. It opens a connection to the Git server and reads the repository. The cluster needs outbound access to Git and the Git server needs no access to the cluster. The credential for the cluster API stays inside the cluster, and the credential for Git is read-only for the agent. The agent compares the two states again and again, so a change made by hand is noticed.

## The components of Argo CD

Argo CD runs as a set of workloads in the namespace `argocd`:

| Component | Job |
| --- | --- |
| `argocd-repo-server` | Clones the repository, runs the tool that renders the manifests (plain YAML, Kustomize or Helm) and returns the result |
| `argocd-application-controller` | Reads each `Application`, asks the repo server for the desired manifests, reads the live objects, compares them and applies changes |
| `argocd-server` | The API and the web interface |
| `argocd-redis` | A cache for the rendered manifests and the live state. It can be deleted and rebuilt |
| `argocd-applicationset-controller` | Creates `Application` objects from templates. It is not needed in this module |

The state of the system is stored in Kubernetes objects. An `Application` is a custom resource in the namespace `argocd`, so the list of what Argo CD manages is itself data in the cluster.

## The Application object

An `Application` has three inputs:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: scout
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git
    targetRevision: main
    path: apps/scout
  destination:
    server: https://kubernetes.default.svc
    namespace: starfleet
  syncPolicy:
    automated: {}
```

- `source` names the repository, the revision (a branch, a tag or a commit) and the folder. Argo CD detects the tool from the files in the folder. A folder with `kustomization.yaml` is rendered with Kustomize. A folder with plain YAML is applied as it is.
- `destination` names the cluster and the namespace. `https://kubernetes.default.svc` is the cluster that Argo CD runs in.
- `syncPolicy` says whether the controller applies changes by itself.

The field `project` selects an `AppProject`, which limits what the application may do. The name `default` allows everything.

## The loop

The controller handles an `Application` in a loop with these steps:

1. It asks the repo server for the manifests at `source`. The repo server clones the repository, checks out `targetRevision` and renders the folder. It caches the result by commit.
2. It reads the live objects that belong to the application from the cluster.
3. It compares the rendered manifests with the live objects, field by field. Fields that the API server fills in or that other controllers own are ignored in the comparison.
4. It writes the result to `status.sync.status`: `Synced` when they are equal and `OutOfSync` when they differ.
5. If the sync policy allows it, or when a person starts a sync, it applies the rendered manifests with a server-side or client-side apply.
6. It reads the health of the live objects and writes `status.health.status`.

Two timers start the loop. The controller refreshes each application every 3 minutes by default, which is the setting `timeout.reconciliation` in the ConfigMap `argocd-cm`. The controller also watches the live objects in the cluster, so a change to a live object starts a comparison at once. A change in Git is not seen at once: the repository server finds it on the next refresh. A webhook from the Git server can start a refresh sooner.

## Two statuses, two questions

`status.sync.status` answers: does the cluster equal Git? `status.health.status` answers: do the objects work? They are independent:

| Sync | Health | Meaning |
| --- | --- | --- |
| `Synced` | `Healthy` | The cluster equals Git and the Deployment has ready pods |
| `Synced` | `Degraded` | The cluster equals Git, but the Deployment does not become ready. Git holds a faulty change |
| `OutOfSync` | `Healthy` | The pods work, but the live state differs from Git. A person changed the cluster, or Git has a new commit not yet applied |
| `OutOfSync` | `Progressing` | A sync is in progress |

A faulty commit can give `Synced` and `Degraded`. Reconciliation does not judge whether the content of Git is right.

## What the status records

The status holds the evidence of the last comparison:

```sh
kubectl -n argocd get application scout -o jsonpath='{.status.sync.status} {.status.sync.revision} {.status.health.status}{"\n"}'
```

- `status.sync.revision` is the commit hash that the live state was compared with.
- `status.operationState` holds the result of the last sync: the phase (`Succeeded`, `Failed`, `Running`), the message and the list of synced resources.
- `status.resources` lists each object with its own sync and health status.

The revision is the link between a live cluster and a commit. If the revision equals the head of the branch in Git and the status is `Synced`, the cluster matches the head.

## Requesting a refresh

A person or a script can ask for a refresh without waiting for the timer. The annotation `argocd.argoproj.io/refresh` on the `Application` starts one: the value `normal` re-reads the cached state and the value `hard` also clears the cache of rendered manifests. The controller removes the annotation when it is done.

```sh
kubectl -n argocd annotate application scout argocd.argoproj.io/refresh=hard --overwrite
```

This is the same mechanism that the web interface uses for the refresh button.

## Reconciliation versus delivery

A pull loop makes the cluster equal to Git. It does not decide when a change is allowed. If Git holds a bad commit, the agent applies it. Safe delivery needs review of the commits, tests before the merge, and a release strategy such as a canary. The pull loop gives you three properties: the desired state is in one place, every change has a commit as its record, and drift is found.

## Try it

In the playground:

1. Run `kubectl -n argocd get application`. Read the columns for sync and health.
2. Run the `jsonpath` command above and note the revision.
3. Open the repository through a port-forward to `svc/gitea-http` in the namespace `gitea` and compare the commit hash with the revision.
4. Trigger a hard refresh with the annotation and watch `status.sync.status` and the annotation with `kubectl get application scout -o yaml`.
5. Run `kubectl -n starfleet get deployment scout -o yaml` and find the label `app.kubernetes.io/instance`. Argo CD uses it to track which objects belong to the application.
