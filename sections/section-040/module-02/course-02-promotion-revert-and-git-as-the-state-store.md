---
draft: true
exam_objectives:
  - Architecture Patterns (in-cluster and external reconciler, state store management, etc.)
---
# Promotion, Revert And Git As The State Store

In a GitOps setup, a release is a commit. A promotion moves a change from one environment to the next, and an undo is another commit. This part shows how these steps work in Git, what Git holds as state, and what the cluster and Argo CD hold that Git does not.

## Promotion is a commit to the next environment

A change is made first in the earliest environment, for example `dev`. When it has proven itself there, the same change is made in the next environment. In a layout with one overlay per environment, the promotion is a commit that edits only the overlay of the target environment so that its values equal the values that worked.

What is promoted depends on what differs between environments:

- The version of the application, usually an image tag in the overlay. This is the most common case.
- A setting that was tested in one environment first.
- A reference to a commit: instead of copying values, the `Application` of `prod` can point `targetRevision` at a tag or a commit hash, while `dev` follows the branch `main`. Promotion then moves the tag or the hash.

Three rules keep promotion safe:

1. Promote by a commit and not by a command against the cluster. The commit has an author, a time, a message and a review. A command against the cluster has none of them.
2. Change only the target environment. If the promotion commit also edits the base, it changes every environment, including those that were not meant to change.
3. Promote a value that was tested. Copy the exact version from the earlier environment. A promotion that rebuilds the artifact from source promotes something different from what was tested.

An automated promotion is a program that makes this commit after the earlier environment is healthy. The program writes to Git like a person does, and the history shows it. The reconciler stays the same.

## History is the record of what was released

Git history answers questions that the cluster cannot:

- `git log --oneline -- overlays/prod` lists every change to production, with the author and the message.
- `git diff <commit> <commit> -- overlays/prod` shows exactly what changed between two releases.
- `git blame` on a line of an overlay shows the commit that set the value.
- The field `status.sync.revision` of an `Application` names the commit that the cluster was compared with. Together with the history, it tells which release runs now.

The cluster only knows its current state. If a value in `prod` was `3` yesterday and is `2` today, the cluster does not keep the earlier value. Git keeps it.

## Undoing a change: revert, not rewrite

A faulty commit reached `main` and the reconciler applied it. There are two ways to remove it from the history that the cluster follows.

| Method | What it does | Effect on the reconciler |
| --- | --- | --- |
| `git revert <commit>` | Adds a new commit that applies the opposite change | The branch head moves forward. The reconciler compares the new head and applies the opposite change |
| `git reset` and a forced push | Moves the branch back and discards the commit from the branch | The branch head moves to an older commit. Other clones now disagree with the server history |

`git revert` is the safe method for a shared branch:

```sh
git log --oneline
git revert <commit>
git push origin main
```

The command opens an editor for the message, or accepts it with `--no-edit`. The new commit has a subject that begins with `Revert` and a body with the line `This reverts commit <hash>.` The original commit stays in history. The history now shows the mistake and the correction, which is what an audit needs.

Details to know:

- A revert is a normal commit. It can be reviewed, and it can itself be reverted.
- If other commits changed the same lines after the faulty commit, the revert can conflict. Git stops and asks for a resolution, and the result is committed as part of the revert.
- To revert a merge commit, Git needs to be told which parent is the mainline with `-m 1`.
- A forced push rewrites a branch. Every clone and every tool that remembered the old head sees a branch that no longer contains the commit it knew. Protect the main branch against forced pushes.

When time matters, a second route exists: change the `Application` to point `targetRevision` at the last good commit. The cluster returns to that state at once, and the branch keeps its history. This is a temporary measure. The state in Git and the state in the `Application` now disagree, so the correction must follow as a revert, and `targetRevision` goes back to the branch.

The pull loop does not judge commits. A revert commit is delivered like any other, so the time to recover is the time to notice, to write the revert and to reconcile.

## What Git stores and what it should not

The repository stores the desired state. What belongs in it:

- The manifests, the overlays and the `Application` and `AppProject` objects.
- The version of every deployed artifact.
- The settings that differ between environments.

What does not belong in it, in clear text:

- Passwords, tokens, private keys and any other secret. Git history keeps every version of every file, so a secret that was committed once stays in the history even if a later commit removes it.
- Values that the cluster generates, such as the node a pod runs on or a status field.
- Large binary files and data. Git holds the description of the workload, not the data of the workload.

Secrets still have to reach the cluster. Common routes keep Git free of secret values:

- Store the secret encrypted in Git and let a controller in the cluster decrypt it. Only the cluster holds the key.
- Store a reference in Git, for example the name of a secret in an external secret store, and let a controller in the cluster fetch the value and create the Kubernetes Secret.
- Create the Secret by a separate process outside GitOps. This leaves one part of the desired state outside Git and must be documented.

## What the cluster holds

Argo CD stores its own state in the cluster:

- `Application` and `AppProject` objects are Kubernetes objects. If they come from Git, Git is their source and the cluster holds a copy.
- Repository and cluster credentials are Secrets in `argocd`.
- `status` fields hold the results of the comparison. They can be rebuilt.
- Redis holds a cache that can be rebuilt.

The cluster also holds data that Git does not describe: the contents of volumes, the rows of a database, and the Secrets created outside GitOps.

## Rebuilding a cluster from Git

Because the desired state is in Git, a new empty cluster can be brought to the same state:

1. Create the cluster and install the reconciler once, by hand or by a script.
2. Give it the credentials for the repository, and for any external secret store.
3. Apply one root `Application` that points at the folder with the other `Application` objects.
4. The reconciler creates the applications and applies the manifests.

What this does not restore: data in volumes and databases, and everything that was created outside Git. A recovery plan lists them, with a separate backup for each.

The same property makes a rebuild a test. If the new cluster does not come up equal to the old one, something was changed by hand and never written to Git. That difference is a finding.

## Drift between Git and the cluster

Git is the source of truth only while the cluster is held to it. A person who edits an object by hand creates drift. With self-heal on, the controller reverts the edit. With self-heal off, it reports `OutOfSync` and waits. Either way, a hand edit that should stay must be written to Git.

## Try it

In the playground:

1. Clone the repository and run `git log --oneline` to read the history. Run `git log --oneline -- overlays/prod`.
2. Change the value in `overlays/dev`, commit and push. Read `status.sync.revision` of `scout-dev` after a refresh and compare it with `git rev-parse HEAD`.
3. Copy the same value into `overlays/prod` in a second commit and push. Compare `git diff HEAD~1 HEAD` with the cluster.
4. Make a faulty commit, for example set `count` of the prod overlay to 0. Read the Deployment in `scout-prod`. Run `git revert --no-edit HEAD`, push, and read the Deployment again.
5. Read `git log` and find the line `This reverts commit` in the body of the revert commit.
