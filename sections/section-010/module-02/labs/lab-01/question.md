# Question

Solve this question on: `terminal`

The namespace `starfleet` runs two releases. Do not delete any Deployment and do not scale any Deployment except `probe-canary`.

1. The Service `scout` serves the application from the Deployment `scout-blue`. The Deployment `scout-green` runs the new version and is ready. Switch the Service `scout` so that its traffic goes to the green pods only. The blue pods must keep running with 2 ready replicas so that a switch back stays possible.

2. The Service `probe` is meant to send a share of its traffic to the canary Deployment `probe-canary`. The stable Deployment `probe-stable` has 3 replicas. The canary must receive 25 percent of the traffic, counted as the share of canary pods among all ready pods behind the Service. Fix the Service and the canary so that the Service has 3 stable and 1 canary ready pods behind it.

3. Record the result in a ConfigMap `release-evidence` in `starfleet` with these keys:
   - `active-track`: the track that the Service `scout` serves now.
   - `canary-percent`: the canary share as a whole number without a percent sign.
   - `observed-at`: the time of your last check in UTC, in the form `2026-11-03T10:15:00Z`.

`kubectl` already points at the cluster as the cluster administrator. The pods carry the label `track`.

Check your work with `astrona submit`.
