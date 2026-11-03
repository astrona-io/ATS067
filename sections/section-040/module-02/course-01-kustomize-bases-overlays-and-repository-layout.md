---
draft: true
exam_objectives:
  - Architecture Patterns (in-cluster and external reconciler, state store management, etc.)
---
# Kustomize Bases, Overlays And Repository Layout

Most teams run the same application in more than one environment, for example `dev` and `prod`. The manifests are nearly equal and differ in a few values: the replica count, the version, a setting, the namespace. This part shows how to keep the shared part once and the differences small, and how the folders of a repository are arranged around that.

## The problem with copies

The first solution is a folder per environment with a full copy of every manifest. It works, and it has two faults:

- A change that belongs in every environment must be made in every copy. One copy is forgotten, and the environments drift apart without anyone deciding it.
- A reader cannot see what differs between `dev` and `prod` without comparing every file.

The second solution is a template language that fills in values. It removes the copies, and the manifests are no longer plain YAML in Git. What the cluster receives is the result of a program, and a reader must run the program to know it.

Kustomize takes a third path. The shared manifests stay plain YAML. A small file per environment says how to change them. The result is built from both.

## Base and overlay

A Kustomize layout has two kinds of folders:

```text
base/scout/
  deployment.yaml
  service.yaml
  kustomization.yaml
overlays/dev/
  kustomization.yaml
overlays/prod/
  kustomization.yaml
```

The base folder holds the manifests that are common to all environments and a `kustomization.yaml` that lists them:

```yaml
resources:
  - deployment.yaml
  - service.yaml
```

An overlay is a folder whose `kustomization.yaml` names the base as a resource and then describes changes:

```yaml
resources:
  - ../../base/scout
namespace: scout-prod
replicas:
  - name: scout
    count: 2
patches:
  - target:
      kind: Deployment
      name: scout
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/env/0/value
        value: release-1
```

Read it:

- `resources` with a path to another folder includes everything that folder builds. The path is relative to the overlay.
- `namespace` sets the namespace on every namespaced object of the result. The manifests in the base do not need a namespace of their own.
- `replicas` sets the replica count of the named Deployment, without a patch.
- `patches` with a `target` applies a change to the matching object. The text in `patch` is a JSON 6902 list of operations (`add`, `replace`, `remove`) or a strategic merge patch. The `path` is a JSON pointer into the object. In this example the value of the first environment variable of the first container is replaced.
- `images` can set a new image name or tag for a container image, which is the usual way to change the version in an overlay.

Nothing in the base is edited. The overlay holds the differences, and a reader sees the differences by reading one short file.

## Rendering to see the result

Kustomize is built into `kubectl`. The command renders an overlay without applying it:

```sh
kubectl kustomize overlays/prod
```

The output is the final YAML that would be applied: the base objects with the changes of the overlay. This is the same text that Argo CD builds. Rendering before a commit is the way to review a change to an overlay.

## How Argo CD uses it

When the folder of an `Application` contains a `kustomization.yaml` (or `kustomization.yml` or `Kustomization`), the repo server detects Kustomize and runs the build. The `Application` does not need to say so. It points at the overlay:

```yaml
spec:
  source:
    repoURL: http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git
    targetRevision: main
    path: overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: scout-prod
```

So `dev` and `prod` are two `Application` objects that differ in `path` and in `destination.namespace`, and both read the same base. A commit that changes the base changes both. A commit that changes one overlay changes one environment.

The `Application` can also carry Kustomize options in `spec.source.kustomize`, such as `images`, `namePrefix` or `replicas`. These belong in the `Application` and not in Git, so a reader of the repository does not see them. Prefer to keep the differences in the overlay files in Git.

## Layouts of a repository

There are four common ways to arrange environments.

| Layout | How an environment is represented | Promotion |
| --- | --- | --- |
| Folders in one branch | One overlay folder per environment on `main` | A commit that edits the next overlay |
| One branch per environment | `dev`, `staging` and `prod` branches with the same folder | A merge from one branch to the next |
| One repository per environment | Separate repositories | A pull request across repositories |
| One repository per application | The application and its overlays live together | As the first layout, inside each repository |

Folders in one branch is the layout that the hands-on steps use, and it is the one that causes the fewest surprises:

- One branch has one history. A change to `prod` is a commit on `main`, and `git log` shows it next to the commits to `dev`.
- A reader can compare two environments with a plain `diff` of two folders.
- There is no merge between environment branches. Merges between long-lived branches carry unrelated differences with them and create conflicts, so the branches slowly stop being equal in the parts that should be equal.

A branch per environment looks natural, since a branch is a line of history. Its cost is the merge: a change to a file that exists differently in the two branches gives a conflict, and the correct result is a decision that a person must repeat at each promotion.

A repository per environment gives the strongest access control: the people who may change `prod` are the people with write access to its repository. The cost is the work to keep several repositories in step, and a change that spans environments needs several pull requests.

## Ownership and access

A layout also decides who may change what. Git hosting systems apply access rules to branches, to paths and to repositories:

- Protected branches require a review before a commit reaches `main`.
- A code owners file can require a named team to review changes to a path such as `overlays/prod/`.
- Separate repositories can have separate write access.

Pick the layout by the rule you need to enforce. If `prod` must be changed only by a small team, a code owners rule on `overlays/prod` on one branch can give that, with less work than a second repository.

## Application and environment definitions are separate things

The `Application` objects tell Argo CD what to deploy. The overlays tell Kustomize what the manifests contain. Both can live in the same repository, in different folders, and a root `Application` can apply the `Application` objects. Keeping them apart has a use: the people who add a new environment (a new `Application`) and the people who change the content of an environment (an overlay) are often different.

## What a layout cannot fix

A good layout keeps environments equal where they should be equal and different where they must differ. It does not decide when a change is ready for the next environment. That is the promotion process, with its tests and reviews.

## Try it

In the playground:

1. Clone the repository through a port-forward to `svc/gitea-http` and open `base/scout`, `overlays/dev` and `overlays/prod`.
2. Run `kubectl kustomize overlays/dev` and `kubectl kustomize overlays/prod` and compare the two outputs with `diff`. List every line that differs.
3. Run `kubectl -n argocd get application scout-dev scout-prod -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.source.path}{" "}{.spec.destination.namespace}{"\n"}{end}'`.
4. Edit the base, for example the memory limit in `base/scout/deployment.yaml`. Commit and push. Check that both environments are updated after a refresh.
5. Edit only `overlays/dev` and check that `prod` does not change.
