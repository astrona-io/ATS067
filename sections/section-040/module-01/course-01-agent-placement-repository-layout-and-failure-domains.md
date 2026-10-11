---
draft: true
exam_objectives:
- Architecture Patterns (in-cluster and external reconciler, state store management,
  etc.)
---
# Agent Placement, Repository Layout And Failure Domains

A GitOps architecture connects authoritative state, management agents and target environments. It may also include rendering services, artifact registries, secret providers and notification paths. Each connection has an identity and failure contract. Drawing these relationships is useful only when the explanation identifies what each component owns and which conditions it can actually repair.

An in-cluster agent runs within the environment it manages. It can use an assigned service identity and may reduce the need for a central service to hold many target credentials. Its operation also depends on the cluster being sufficiently available. A failure that prevents the agent from running can require a recovery path outside that same environment.

An external agent can manage one or several targets from a separate service. This can centralize configuration and operational visibility. It can also concentrate target access and create a shared dependency whose outage affects several environments. Least privilege and target isolation remain necessary even when one service presents a convenient unified interface.

Consider a platform managing development and production clusters. Separate in-cluster agents can limit each identity's scope and failure impact. A central agent can simplify shared operation but needs suitable target credentials and policy separation. Neither placement automatically wins. The decision should consider trust, recovery, operational capacity and the consequences of a compromised management service.

Repository layout is another architectural choice. Application source can be separate from deployment intent, allowing build output and environment approval to follow different paths. A shared base can reduce duplication while overlays express environment-specific choices. A monorepo can provide atomic related changes but can also widen review scope. Separate repositories can clarify ownership while requiring coordination across versions.

The layout should make environment authority visible. A production path should not accidentally follow an unrelated development branch or inherit unreviewed mutable defaults. Shared changes can affect several consumers, so their version and adoption contract need review. A folder name alone does not establish an approval boundary; access controls and agent selection implement that boundary.

Rendering placement affects capacity and trust. A central rendering service can share tools and cache artifacts, while local rendering can keep responsibilities nearer to the agent. Both need known input versions and protected handling of secrets. Rendering untrusted templates can have security implications according to the tool and plugin support. The architecture should avoid treating every source file as harmless.

Bootstrap and recovery identify how the first trusted agent, credentials and source references are established. Self-management can maintain later configuration but cannot eliminate every dependency needed to recover from a broken trust path. Operators need a known way to restore source access or management installation when the normal controller cannot act.

Deletion and retirement also cross architecture boundaries. Removing an environment path can trigger cleanup under the agent's policy. Persistent resources may require retention or handoff rather than automatic destruction. The source layout, controller ownership and data lifecycle should agree so a repository cleanup does not accidentally become an infrastructure outage.

Useful status connects each target to its source and resolved revision. Notifications and dashboards then describe actual evaluation rather than only source commits. This lets students trace a proposed change from its approval path through rendering and agent action to runtime outcome, with the relevant authority and failure boundary at each step.

## Common pitfalls

> [!WARNING]
> Agent placement and folder layout do not automatically establish least privilege or approval policy. Central services can concentrate access and failure impact. Document bootstrap, recovery, shared-input versions and persistent-resource retirement explicitly.
