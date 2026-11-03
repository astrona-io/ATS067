---
draft: true
exam_objectives:
  - Architecture Patterns (in-cluster and external reconciler, state store management, etc.)
---
# Where The Reconciler Runs: In-Cluster, Hub And Per-Cluster Agents

A GitOps reconciler is a program that reads a desired state and changes a cluster to match it. The program must run somewhere, and the place decides which credentials exist, which network connections are opened and what breaks when something fails. This part compares the three common placements.

## What every placement has to do

Whatever the placement, the reconciler needs three things:

1. A way to read the repository: a URL and, for a private repository, a credential.
2. A way to read and change objects in the target cluster: the address of the Kubernetes API server and a credential for it.
3. A place to keep its own state: which applications exist, what was compared last and what is cached.

The placements differ in where the program runs relative to the target cluster, and therefore in how the second item is solved.

## Placement 1: the reconciler runs inside the cluster it manages

This is the default install of Argo CD. All components run in the namespace `argocd` of the cluster that they manage:

- `argocd-application-controller` is a StatefulSet. It compares and applies.
- `argocd-repo-server` is a Deployment. It clones repositories and renders manifests.
- `argocd-server` is a Deployment. It serves the API and the web interface.
- `argocd-redis` is a Deployment. It caches rendered manifests and live state.

The target cluster is addressed as `https://kubernetes.default.svc`. That name resolves inside the cluster to the API server. The application controller talks to the API server with a ServiceAccount token that Kubernetes mounts in its pod, and the RBAC of that ServiceAccount decides what Argo CD can change. The install grants it broad rights, because it must be able to apply any kind of object that an application contains.

No cluster credential is stored as a Secret in this placement. The cluster named `in-cluster` is implicit. The only credential that Argo CD may hold is the one for the Git repository, and only when the repository is private.

Network connections in this placement:

- Repo server to the Git server: outbound from the cluster.
- Application controller to the API server: inside the cluster.
- Users to `argocd-server`: inbound to the cluster, only for people who use the interface or the CLI.

The cluster does not accept any connection from the Git server. This is why a pull-based agent works behind a firewall that allows only outbound traffic.

## Placement 2: one hub manages many clusters

A team with many clusters can run one Argo CD in a management cluster, called the hub, and register the other clusters as destinations. The hub applies manifests to the registered clusters over the network.

To register a cluster, Argo CD needs the address of its API server and a credential. They are stored as a Secret in the namespace `argocd`, labeled `argocd.argoproj.io/secret-type: cluster`. The Secret has these keys:

| Key | Content |
| --- | --- |
| `name` | The name that an `Application` can use in `destination.name` |
| `server` | The URL of the API server of the target cluster |
| `config` | JSON with the credential: a bearer token or a client certificate, and the TLS settings |

The command `argocd cluster add` creates this for you. It creates a ServiceAccount named `argocd-manager` in the target cluster, binds a ClusterRole to it, reads its token and writes the Secret in the hub. You can also create the Secret yourself from a manifest, which makes the registration part of the declared state.

Network connections in this placement:

- Hub to the API server of each target cluster: outbound from the hub, inbound to each target.
- Hub to the Git server: outbound from the hub.
- Target clusters to Git: none.

What this placement gives:

- One place to see and manage all applications, and one place to apply rules (projects, RBAC, single sign-on).
- Less to run: one set of controllers instead of one per cluster.

What it costs:

- The hub holds a credential with write access to every registered cluster. If the hub or its Secrets are taken over, every cluster is open. The hub is a high-value target.
- Each target API server must be reachable from the hub. A target in a private network needs a route or a tunnel.
- One controller handles all applications. A large number of applications and clusters needs sharding of the controller, so that each replica handles a subset of clusters.

## Placement 3: one reconciler per cluster

Each cluster runs its own Argo CD and manages only itself with the implicit `in-cluster` destination. A shared repository holds the applications for all clusters, usually with one folder or one overlay per cluster.

What this placement gives:

- A small blast radius. A taken-over reconciler can change only its own cluster.
- No credential for any cluster API leaves that cluster.
- A failure of one reconciler affects one cluster only.

What it costs:

- N installs to keep at the same version, and N places to apply configuration.
- No single view of all clusters, unless an extra layer collects the status.

Some teams combine the two: a small hub installs and updates the per-cluster Argo CD instances, and each instance then manages only its own cluster.

## Push versus pull, seen as credentials

The three placements move the cluster credential to different places:

| Placement | Who holds a credential that can change the cluster API | Direction of the connection to the API |
| --- | --- | --- |
| Push from CI | The CI system | CI to cluster |
| Hub | The hub | Hub to each cluster |
| In-cluster or per-cluster | A ServiceAccount inside the cluster | Inside the cluster |

The pull model in its in-cluster form is the only one where nothing outside the cluster can change the cluster API. In the hub form, Argo CD reads Git by pull, but it still pushes to the target clusters, so the target API servers must accept the hub.

## Failure domains of Argo CD

A failure domain is a part that can fail on its own and the set of things that stop working with it. For the in-cluster placement, list each part and what is lost:

| Part that stops | What stops working | What keeps working |
| --- | --- | --- |
| `argocd-application-controller` | Comparison, status updates, automated sync and self-heal | All running workloads. The pods, Services and everything already applied stay as they are |
| `argocd-repo-server` | Rendering of new manifests, so no new comparison or sync | Workloads. The controller reports errors on the applications |
| `argocd-server` | The web interface, the API and the CLI | The controller still reconciles from `Application` objects |
| `argocd-redis` | Cache. The components rebuild it and run slower for a while | Workloads and the state in the `Application` objects |
| The Git server | Fetching new commits. The repo server may serve cached results for a time | Workloads. No change is delivered until Git returns |
| The API server of a target | Everything for that target | Other targets. The workloads on the target keep running if the node agents still work |

Two facts follow from this table:

1. Argo CD is a control plane, not a data plane. The workloads do not depend on it for serving traffic. If it stops, the cluster freezes at the last applied state and drift is no longer corrected.
2. The state that matters is in Git and in the `Application` objects. Redis is a cache. A lost cache costs time, not data.

Stopping a controller does not undo anything. Starting it again makes it compare the current live state with Git and, with automated sync, apply any difference that built up.

## Bootstrap: who installs the reconciler

The reconciler cannot install itself the first time. Something outside GitOps creates the namespace and applies the install manifests once. After that, the reconciler can manage its own configuration:

- A root `Application` points at a folder that contains other `Application` objects. The reconciler creates them, so a new application is added by a commit. This is the app-of-apps pattern.
- The `Application` for Argo CD itself can point at the folder with its own manifests. A bad commit there can break the reconciler. Keep a way to apply the install by hand.

The bootstrap step is the only step that needs a person or a script with administrator rights. Write it down and keep it small.

## Choosing a placement

| Question | Points to |
| --- | --- |
| Must a cluster accept no inbound connection from other clusters? | In-cluster or per-cluster |
| Is one team responsible for a handful of clusters and wants one view? | Hub |
| Does a compromised management plane need to be limited to one cluster? | Per-cluster |
| Are there many small clusters and little operations capacity? | Hub, with sharding |
| Do clusters belong to different customers or trust zones? | Per-cluster |

## Try it

In the playground:

1. Run `kubectl -n argocd get deploy,statefulset` and name the four components from the table.
2. Run `kubectl -n argocd get secret -l argocd.argoproj.io/secret-type=repository`. Find the credential that Argo CD holds for the Git repository and read the keys with `kubectl -n argocd get secret repo-fleet -o jsonpath='{.data}'`. The values are base64 text, not encrypted.
3. Run `kubectl -n argocd get secret -l argocd.argoproj.io/secret-type=cluster`. Note that no Secret exists for the in-cluster destination.
4. Scale the application controller to zero with `kubectl -n argocd scale statefulset argocd-application-controller --replicas=0`. Confirm that `kubectl -n starfleet get pods` still shows the workloads. Scale the Deployment `scout` by hand to 5 and note that nothing reverts it.
5. Scale the controller back to 1 and watch the Application. With self-heal on, the replica count returns to the value in Git.
