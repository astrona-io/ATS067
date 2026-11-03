---
draft: true
exam_objectives:
  - Progressive Delivery Patterns
---
# Summary

- A Rollout replaces a Deployment. The Argo Rollouts controller creates one ReplicaSet per pod template and labels pods with `rollouts-pod-template-hash`.
- `status.stableRS` is the version treated as stable and `status.currentPodHash` is the version in the template. They are equal when a release is complete.
- The canary strategy walks a list of steps in order. `setWeight` sets the target share, a `pause` with a duration continues by itself, and a `pause` without a duration waits for a promotion.
- Without a traffic router the weight is expressed in pod counts. The controller picks the whole-number split closest to the target and rounds up on a tie, so the real share is an estimate.
- `stableService` and `canaryService` get selectors that the controller edits with the hash labels. They give a stable address and a canary address.
- The blue-green strategy runs the new version beside the old one. The preview Service follows the newest ReplicaSet and the active Service changes at promotion.
- `autoPromotionEnabled: false` makes the Rollout wait in the phase `Paused`, which is a normal state and not a failure.
- `scaleDownDelaySeconds` keeps the old ReplicaSet running after the switch, so connections can finish and a quick return is possible.
- Read state without the plugin: `status.phase`, `status.currentStepIndex`, `status.stableRS`, the pause conditions and the endpoints of each Service.
- A weight of 25 is one pod of four and not exactly 25 percent of the requests, and a preview test is not proof of production behavior.

<!-- astrona:playground:destroy -->
