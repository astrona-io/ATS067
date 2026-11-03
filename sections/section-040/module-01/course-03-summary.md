---
draft: true
exam_objectives:
  - Architecture Patterns (in-cluster and external reconciler, state store management, etc.)
---
# Summary

- A reconciler needs a repository credential, a cluster credential and a place for its state. The placement decides where each of them lives and which side opens the connection.
- In-cluster placement uses a ServiceAccount token inside the cluster and no cluster Secret. A hub holds a cluster credential for each registered cluster in a Secret labeled `argocd.argoproj.io/secret-type: cluster`. A per-cluster agent keeps each blast radius to one cluster.
- A hub gives one view and one place for rules, and costs a high-value credential and reachability of every target API. Per-cluster agents cost more installs and give a small blast radius.
- Argo CD is a control plane. If the application controller, the repo server or the Git server stops, the running workloads keep running. Drift is not corrected and changes are not delivered until the part returns.
- Redis is a cache. The state that matters is Git and the `Application` objects.
- An `AppProject` limits `sourceRepos`, `destinations`, and the kinds that may be deployed. The project `default` allows everything.
- An application that breaks its project gets the condition `InvalidSpecError` and is not synced. A project does not delete what is already running.
- Repository credentials are Secrets with the label `argocd.argoproj.io/secret-type: repository`. They are base64 text, should be read-only, and need access control on the namespace `argocd`.
- Limits stack: Git review, the project, the credential and admission control each decide on their own.

<!-- astrona:playground:destroy -->
