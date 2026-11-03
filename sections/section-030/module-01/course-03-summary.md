---
draft: true
exam_objectives:
  - Pull vs. Event-driven
---
# Summary

- A pull-based agent runs in the cluster and reads Git. The cluster needs outbound access to Git, and Git needs no access to the cluster API. A push pipeline holds a cluster credential and changes the cluster only when it runs.
- An `Application` has a `source` (repository, revision, path), a `destination` (cluster and namespace) and a `syncPolicy`. The `project` field limits what the application may do.
- The repo server renders the manifests, the application controller compares them with the live objects, and the result is `status.sync.status` (`Synced` or `OutOfSync`) and `status.health.status`. These two statuses are independent.
- The controller refreshes every 3 minutes and also reacts to changes of live objects. A change in Git is found on the next refresh or on a requested refresh. The annotation `argocd.argoproj.io/refresh` requests one.
- `status.sync.revision` holds the commit that the cluster was compared with. It links a live state to a commit.
- Without `automated`, sync is manual and the controller only reports. With `automated: {}`, a new commit is applied, but removed files are not pruned and live changes are not reverted.
- `prune: true` deletes tracked objects whose manifest was removed from Git. `selfHeal: true` reverts live changes to the fields that Git sets. `allowEmpty` protects against an empty folder.
- Reconciliation makes the cluster equal to Git. It does not judge the content of a commit.

<!-- astrona:playground:destroy -->
