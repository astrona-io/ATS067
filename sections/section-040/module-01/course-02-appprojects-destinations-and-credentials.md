---
draft: true
exam_objectives:
  - Architecture Patterns (in-cluster and external reconciler, state store management, etc.)
---
# AppProjects, Destinations And Credentials

An Argo CD installation is shared by many teams. Without a limit, any `Application` can read any repository the installation can read and write to any namespace the installation can write to. The `AppProject` is the object that draws those limits. This part shows what a project limits, how the check works, and where the credentials live.

## What an AppProject is

An `AppProject` is a custom resource in the namespace `argocd`. Every `Application` names exactly one project in `spec.project`. If the field is empty, the name is `default`. The project named `default` exists in every installation and allows everything: any repository, any destination and any kind of object.

A project limits four things:

| Field | What it limits |
| --- | --- |
| `sourceRepos` | Which repository URLs an `Application` of the project may read |
| `destinations` | Which clusters and namespaces an `Application` may deploy to |
| `clusterResourceWhitelist` and `clusterResourceBlacklist` | Which cluster-scoped kinds (for example `Namespace`, `ClusterRole`) may be deployed |
| `namespaceResourceWhitelist` and `namespaceResourceBlacklist` | Which namespaced kinds may be deployed |

A project can also hold roles for access control and a list of sync windows. These are not needed to understand the limits.

## A project written out

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: crew
  namespace: argocd
spec:
  description: Applications of the crew team
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: starfleet
  clusterResourceWhitelist: []
```

Read it field by field:

- `sourceRepos` is a list of URL patterns. An application of this project can use only this repository. The pattern `*` matches every repository. A pattern with a prefix, such as `http://gitea-http.gitea.svc:3000/starfleet/*`, matches every repository of the organization. A pattern that begins with `!` denies a match.
- `destinations` is a list of pairs. Each pair names a cluster, by `server` URL or by `name`, and a namespace. Both parts must match. The namespace part also accepts patterns, such as `team-*`. The pair `server: https://kubernetes.default.svc` with `namespace: starfleet` allows the in-cluster destination in one namespace only.
- `clusterResourceWhitelist: []` allows no cluster-scoped kinds. An absent field means the same: if no whitelist is set, cluster-scoped kinds are denied. To allow one, list it with a group and a kind, for example `group: ""` and `kind: Namespace`.
- Namespaced kinds are allowed unless a whitelist or a blacklist is set. A whitelist of `Deployment` and `Service` would deny a `Secret` in the same application.

## The check: when it happens and how it fails

The application controller checks the application against its project in two places.

1. When it reads the application. It compares `spec.source.repoURL` with `sourceRepos` and `spec.destination` with `destinations`. If either is not permitted, the application gets a condition in `status.conditions` with the type `InvalidSpecError`. The message names the destination or the repository and the project. The controller does not sync an application in this state.
2. When it renders the manifests. For each object it checks the kind against the whitelists and blacklists, and the namespace of the object against `destinations`. An object that is not allowed makes the sync fail with a message that names the kind or the namespace.

To read the condition:

```sh
kubectl -n argocd get application intruder -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.message}{"\n"}{end}'
```

A project does not delete what is already running. If you move an application that is already synced to a project that forbids its destination, Argo CD stops syncing it and reports the condition. The objects in the cluster stay until someone deletes them. A project is a gate for future changes, not a cleanup tool.

The `default` project allows everything, so a limit has no effect until applications use another project. The usual practice is one project per team or per environment, and to restrict or remove the `default` project in a shared installation.

## Who may create an Application in which project

The project controls what an application may do. Who may create an `Application` is a separate question, answered by Kubernetes RBAC on the objects in the namespace `argocd` and by the roles in the Argo CD settings. A person who can create `Application` objects in `argocd` can choose any project name. If that matters, restrict creation with RBAC and keep the `Application` objects in a repository that is reviewed. The project then enforces the limits that the reviewers set.

Applications can also be allowed to live in other namespaces. The setting `application.namespaces` and the field `sourceNamespaces` of the project control this. This is out of scope here, but the principle is the same: the project names which namespaces may hold applications that use it.

## Credentials for repositories

Argo CD reads repositories with credentials that it keeps as Kubernetes Secrets in `argocd`. A Secret with the label `argocd.argoproj.io/secret-type: repository` describes one repository:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-fleet
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git
  username: platform
  password: starfleet-gitops
```

- `url` is matched against `spec.source.repoURL` of the applications. The match is by the text of the URL.
- A credential template, a Secret with the label `argocd.argoproj.io/secret-type: repo-creds`, applies to every repository whose URL begins with the given prefix. This avoids one Secret per repository.
- For SSH the keys are `sshPrivateKey` and a URL such as `ssh://git@host/org/repo.git`. For HTTPS they are `username` and `password`, where the password is often a token.
- A public repository needs no Secret.

A repository credential should be read-only. Argo CD only needs to fetch. A credential with write access would let a taken-over Argo CD push to Git, and Git is the source of truth.

Secrets in Kubernetes are base64 text, not encrypted. Anyone who may read Secrets in `argocd` can read the credentials. This is a reason to limit access to the namespace `argocd` and to keep the Secrets out of Git in clear text.

## Credentials for clusters

For a destination other than the cluster that Argo CD runs in, the Secret has the label `argocd.argoproj.io/secret-type: cluster` and the keys `name`, `server` and `config`, as described for the hub placement. The `config` value is JSON. A bearer token looks like `{"bearerToken": "...", "tlsClientConfig": {"insecure": false, "caData": "..."}}`.

Three practices reduce the risk:

1. Give the credential of the target cluster the least rights that the applications need. A ClusterRole with all rights is easy and is also the largest risk.
2. Use short-lived credentials where the platform supports it, for example an identity provided by the cloud for the hub.
3. Let the project, and not only the credential, decide what an application may touch. The credential is the outer limit and the project is the inner limit.

The names `destinations[].name` and `destinations[].server` refer to the same registry. A project that lists `name: prod` allows the cluster that was registered with that name.

## The order of the limits

A change reaches the cluster only if every layer allows it:

| Layer | Decides |
| --- | --- |
| Git review and branch protection | What may be committed to the repository |
| `AppProject` | Which repositories, destinations and kinds an application may use |
| The credential or ServiceAccount of Argo CD | What the API server accepts from Argo CD |
| Admission control in the cluster | What the API server accepts at all, for example policy engines |

Each layer is checked on its own. A weak layer is covered by a strong one, so none of them replaces the others.

## Try it

In the playground:

1. Run `kubectl -n argocd get appproject` and read the project `crew` with `-o yaml`. Find `sourceRepos`, `destinations` and the cluster resource list.
2. Run `kubectl -n argocd get application` and find the project of each application.
3. Run the `jsonpath` command above for the Application `outsider`. Read the message and find which part of the destination is not permitted.
4. Change the namespace in the destination of `outsider` to `starfleet` and watch the condition disappear and the sync start. Change it back.
5. Add `namespaceResourceWhitelist` to `crew` with one entry for the kind `Service` (group empty). Request a hard refresh of `scout` and read the sync error for the Deployment that is no longer allowed. Remove the whitelist again.
