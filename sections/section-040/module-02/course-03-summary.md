---
draft: true
exam_objectives:
  - Architecture Patterns (in-cluster and external reconciler, state store management, etc.)
---
# Summary

- Kustomize keeps shared manifests in a base and the differences of each environment in an overlay. An overlay lists the base in `resources` and changes it with `namespace`, `replicas`, `images` and `patches`. `kubectl kustomize <folder>` renders the result.
- Argo CD detects `kustomization.yaml` in the folder of an `Application`. Two environments are two `Application` objects with different `path` and namespace and the same base.
- Folders per environment in one branch give one history and a plain comparison. A branch per environment needs merges that carry unrelated differences. A repository per environment gives the strongest access control and costs the most coordination.
- Promotion is a commit that edits only the target overlay with a value that was tested. A change to the base changes every environment.
- History answers who changed what and when. `status.sync.revision` ties the running state to a commit.
- `git revert` adds a commit that undoes a faulty commit and keeps the history. A forced push rewrites the branch and breaks every clone and tool that knew the old head.
- Git holds the desired state. Secrets must not be committed in clear text, because history keeps every version. Use encrypted secrets, references to an external store or a separate process.
- A cluster is rebuilt by installing the reconciler, giving it credentials and applying a root `Application`. Data in volumes and databases and anything created outside Git is not restored by this.
- A hand edit that should stay must be written to Git, or the next sync or self-heal removes it.

<!-- astrona:playground:destroy -->
