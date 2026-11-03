# Question

Solve this question on: `terminal`

The Argo Rollouts controller runs in the namespace `argo-rollouts`. In the namespace `starfleet`, two Rollouts run version 1 (`ghcr.io/stefanprodan/podinfo:6.15.0`, message `version-1`). Do not delete or scale a Rollout.

1. The Rollout `scout` releases in a single step. Change its steps to this staged list: `setWeight: 25`, a pause with a duration, `setWeight: 50`, a pause with a duration. Then release version 2: the image `ghcr.io/stefanprodan/podinfo:6.14.0` and the message `version-2` in the environment variable `PODINFO_UI_MESSAGE`. Wait until the release is complete: the Rollout is `Healthy` and all 4 pods run version 2.

2. The Rollout `shield` (blue-green) promotes new versions by itself and starts all preview pods. Change it to wait for a manual promotion and to start only 1 preview pod. Then stage version 2 (the same image and message as above). Do not promote. The Rollout must wait in the phase `Paused`, the Service `shield-active` must still reach the 4 version-1 pods and the Service `shield-preview` must reach 1 version-2 pod.

3. Record the result in a ConfigMap `rollout-record` in `starfleet` with these keys:
   - `scout-stable-rs`: the value of `status.stableRS` of the Rollout `scout`.
   - `shield-active-hash`: the value of the label `rollouts-pod-template-hash` in the selector of the Service `shield-active`.
   - `observed-at`: the time of your last check in UTC, in the form `2026-11-03T10:15:00Z`.

`kubectl` already points at the cluster as the cluster administrator. The Argo Rollouts kubectl plugin is not installed.

Check your work with `astrona submit`.
