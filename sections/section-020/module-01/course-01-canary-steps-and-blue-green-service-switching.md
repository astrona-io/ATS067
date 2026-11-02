---
draft: true
exam_objectives:
- Progressive Delivery Patterns
---
# Canary Steps And Blue-Green Service Switching

Progressive-delivery strategies limit or structure the transition between workload versions. Canary exposes a new version incrementally, while blue-green prepares a separate candidate and switches the active relationship during promotion. Argo Rollouts coordinates those transitions, but their usefulness depends on routing, evidence and recovery design.

## Canary Advances Through Steps

A canary strategy can declare supported weight and pause steps. A step increases intended exposure or waits for a decision before continuing. Analysis can provide evidence for promotion, while an explicit pause can require an operator's judgment. The strategy should state why each stage offers enough traffic and time to evaluate the candidate.

Without supported traffic-routing integration, replica proportions can provide an approximate distribution under some arrangements. With integration, routing resources can express intended weights more directly. Neither should be interpreted as a guarantee of exact user or transaction proportions because persistent connections, retries and client behavior affect observed traffic.

## Stable And Canary Relationships Must Agree

Services or supported routing integration identify stable and canary backend populations. The controller can manage relevant selectors under the strategy. Incorrect selectors or ports can make one version unreachable even when its Pods are ready. Review the actual endpoints and routing state.

A canary receiving almost no traffic cannot establish a meaningful error or latency comparison. Analysis needs a sufficient population and appropriate missing-data handling. A quiet metric may mean low exposure, unavailable collection or healthy behavior; distinguish those cases before advancing.

## Blue-Green Separates Candidate Access

Blue-green maintains an active service relationship and can expose the candidate through a preview Service. Promotion changes which version the active Service selects under the strategy. This supports inspection of the candidate before normal user traffic is shifted.

Preparing both populations requires capacity. A candidate that cannot schedule should not be treated as ready merely because the old version remains available. Service switching also has propagation and connection behavior. Existing connections may not behave identically to new ones during the transition, so recovery and scale-down timing matter.

## Promotion And Abort Need Compatibility

A pause or successful analysis can authorize progression according to the configured contract. An abort can restore or retain the stable relationship under supported behavior. It does not automatically reverse external writes made during exposure. A candidate that changes data schema can leave the stable version incompatible even after traffic returns.

Design backward compatibility and side-effect handling before relying on rollback. Old images, mounted configuration and credentials can have separate lifecycles. The earlier ReplicaSet's presence is useful capacity evidence, not a complete recovery guarantee.

## Choose The Strategy By Risk

Canary can provide gradual evidence under realistic traffic but needs meaningful comparison and routing support. Blue-green can simplify a discrete service switch and preview access but can require substantial duplicate capacity. Both need narrow identities, useful readiness and protected promotion authority.

Document the expected traffic population, observation interval and abort criteria. Compare desired weights with observed outcomes rather than promote because one field reached its final value. The strategy is a controlled experiment in delivery behavior within its supported limits, not automatic proof that the release is harmless.

## Interpret Canary Steps

```yaml
strategy:
  canary:
    steps:
    - setWeight: 10
    - pause: {}
    - setWeight: 50
    - pause:
        duration: 5m
```

The fragment expresses an initial exposure step, an indefinite pause requiring progression under the supported control path, then another exposure step and timed pause. It omits workload and routing configuration. A weight declaration alone does not establish exact observed traffic share.

## Common pitfalls

> [!WARNING]
> Replica proportions, configured weights and observed requests differ. Preview access is not production proof, and returning traffic to a stable version does not undo incompatible external state.
