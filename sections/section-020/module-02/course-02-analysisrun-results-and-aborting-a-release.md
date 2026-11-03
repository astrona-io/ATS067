---
draft: true
exam_objectives:
  - Progressive Delivery Patterns
---
# AnalysisRun Results And Aborting A Release

An `AnalysisTemplate` defines a question. An `AnalysisRun` is one asking of that question. This part follows an analysis from its start to its result, shows how it connects to the steps of a canary release, and explains what the controller does with each result.

## Where the controller creates runs

A canary Rollout can use analysis in two places:

```yaml
strategy:
  canary:
    analysis:
      templates:
        - templateName: quality-gate
      startingStep: 1
      args:
        - name: score
          value: "95"
    steps:
      - setWeight: 25
      - pause: {duration: 30s}
      - setWeight: 50
      - pause: {duration: 30s}
```

The field `strategy.canary.analysis` is a background analysis. The controller starts a run when the release reaches `startingStep` (a step index that starts at 0) and keeps it running while the steps continue. An inline analysis is a step in the list:

```yaml
    steps:
      - setWeight: 25
      - analysis:
          templates:
            - templateName: quality-gate
          args:
            - name: score
              value: "95"
      - setWeight: 50
```

An inline analysis blocks the release at that step until the run ends. The Rollout moves to the next step only when the run is successful.

The Rollout does not run the analysis for the first revision, because there is no old version to compare with. Analysis starts with the first release after that.

## The resource that holds the results

The controller creates an object of the kind `AnalysisRun` in the namespace of the Rollout and makes the Rollout its owner. The run copies the metrics from the template and fills in the argument values. Its status holds one list of measurements per metric:

```sh
kubectl -n starfleet get analysisrun
kubectl -n starfleet get analysisrun -o jsonpath='{range .items[*]}{.metadata.name} {.status.phase}{"\n"}{end}'
```

Each measurement has a phase, a value and a time. The phase of the whole run is the result of its metrics.

## The phases of a run

| Phase | What it means | What the Rollout does |
| --- | --- | --- |
| `Pending` and `Running` | Measurements are still being taken | The release continues, or an inline step waits |
| `Successful` | Every metric ended with success | An inline step ends and the release continues |
| `Failed` | A metric used all its allowed failures | The release is aborted |
| `Inconclusive` | A measurement was neither a success nor a failure | The release pauses until a person promotes or aborts it |
| `Error` | Measurements could not be taken, for example the endpoint was down | The release is aborted after the error limit |

Treat `Error` as different from `Failed`. A failed run says that the version is bad. An error says that the question could not be asked, and the answer is unknown.

## What an abort does

When a run fails, the controller aborts the release. It sets the weight of the canary to 0 and scales the canary ReplicaSet down. The stable ReplicaSet continues to serve. The Rollout gets the phase `Degraded` and `status.abort` is true. `status.stableRS` keeps the hash of the last good version, and `status.currentPodHash` keeps the hash of the failed version.

```sh
kubectl -n starfleet get rollout scout -o jsonpath='{.status.phase} {.status.abort} {.status.stableRS} {.status.currentPodHash}{"\n"}'
```

The two hashes differ and the phase is `Degraded`. Users see only the stable version. The controller does not roll the template back for you: the Rollout resource still holds the failed template, and the desired state still says "release this version". To release again, change the template. A change that produces a new pod template hash starts a new release with new runs. A change of the analysis arguments alone does not change the template, so it does not start a release.

## How abort relates to rollback

An abort is a controller decision that returns traffic to the stable pods. It is quick, because the stable ReplicaSet never scaled down. It does not undo external effects of the canary: records that the canary wrote, messages it sent and schema changes it applied remain.

For a team, the useful practice is to write the abort criteria in the template before the release. A metric that a person looks at during the release is slower than a run that fails by itself, and the person might not look at the right time.

## Reading the evidence

A run is evidence for a release decision. The status lists each measurement with its value. Read these facts after a release:

- Which template and which argument values the run used.
- How many measurements were taken and how many failed.
- The phase of the run, and the phase and the message of the Rollout.
- Whether the failed version ever reached more than the canary share of pods.

The controller deletes old runs after a limit set by `successfulRunHistoryLimit` and `unsuccessfulRunHistoryLimit` in the Rollout spec. Copy the evidence you need into a record before the limit removes it.

## Failure cases to recognise

- The run stays in `Running` for a long time: `count` is not set and the metric never ends. Use `count` or a background analysis that you stop with the end of the release.
- The release passes although the new version is bad: the metric does not depend on the version, or the failure limit is too high.
- The release aborts although the version is good: the metric reads the stable version, or the endpoint is slow and the measurements fail.
- The Rollout is `Degraded` after an abort: this is the correct state. It means that the failed version is not serving.

## Common pitfalls

> [!WARNING]
> An abort protects production traffic. It does not remove the failed version from the Rollout spec and it does not repair side effects. A second release with the same pod template does not start, so change the template to try again.
