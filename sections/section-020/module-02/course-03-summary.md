---
draft: true
exam_objectives:
  - Progressive Delivery Patterns
---
# Summary

- An `AnalysisTemplate` is a reusable definition with arguments and metrics. It does not run. An `AnalysisRun` is one execution that stores the measurements and the result.
- A metric has an `interval`, a `count`, a `successCondition`, optionally a `failureCondition`, and a `failureLimit` that says how many failed measurements it tolerates.
- The web provider sends an HTTP request and reads one value from the JSON body with `jsonPath`. The text of the value becomes `result`, and numbers are converted with functions such as `asInt` before a comparison.
- Arguments make one template usable by many Rollouts. A missing argument without a default is an error.
- A background analysis runs beside the steps from `startingStep`. An inline analysis is a step that blocks until the run ends.
- A `Successful` run lets the release continue. A `Failed` run aborts it. An `Inconclusive` run pauses it. An `Error` run means that the question could not be asked.
- An abort sets the canary weight to 0, keeps the stable pods serving and gives the Rollout the phase `Degraded`. `status.stableRS` keeps the last good hash.
- An abort does not change the template and does not undo side effects. A new release needs a changed pod template.
- A good metric differs between a good and a bad version, has data at a small share, and is measured for the canary.
- Copy the evidence of a run into a record, because the controller removes old runs.

<!-- astrona:playground:destroy -->
