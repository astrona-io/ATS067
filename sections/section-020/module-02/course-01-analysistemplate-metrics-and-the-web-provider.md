---
draft: true
exam_objectives:
  - Progressive Delivery Patterns
---
# AnalysisTemplate Metrics And The Web Provider

A canary step shows that a new version runs. It does not show that the version is good. Argo Rollouts lets a release ask a measurable question and use the answer to continue or to stop. The question is written once in a resource named `AnalysisTemplate`. This part explains what the template contains, how a metric turns a measurement into a pass or a fail, and how the web provider reads a value from an HTTP endpoint.

## A template is a definition, not an execution

An `AnalysisTemplate` is a reusable definition. It has no state and it does not run. It lists the metrics to measure and the arguments that a release must supply. A Rollout refers to the template by name, and the controller creates an `AnalysisRun` from it when a release needs a decision. The run holds the results. The template stays unchanged, so many releases can use it.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: quality-gate
  namespace: starfleet
spec:
  args:
    - name: score
  metrics:
    - name: quality
      interval: 10s
      count: 3
      failureLimit: 0
      successCondition: asInt(result) >= 90
      provider:
        web:
          url: "http://httpbin.analysis.svc.cluster.local:8080/get?score={{ args.score }}"
          jsonPath: "{$.args.score[0]}"
```

The template defines one metric named `quality`. The argument `score` has no default, so every Rollout that uses the template must pass a value.

## The fields of a metric

| Field | Meaning |
| --- | --- |
| `interval` | The time between two measurements |
| `count` | How many measurements to take. When omitted, the metric runs until the analysis is stopped |
| `initialDelay` | A wait before the first measurement |
| `successCondition` | An expression on `result`. A measurement that makes it true is a success |
| `failureCondition` | An expression that makes a measurement a failure. When both conditions exist, the failure condition is checked as well |
| `failureLimit` | How many failed measurements the metric tolerates. The default is 0 |
| `consecutiveSuccessLimit` | How many successes in a row end a metric with success |
| `provider` | Where the measurement comes from, for example `web` |

With `failureLimit: 0`, the first failed measurement fails the metric. With `failureLimit: 2`, the metric fails when the third measurement fails. A failure limit is a way to tolerate noise. It is not a way to hide a real problem, so set it from the known noise of the metric.

## Arguments

A template declares arguments with `spec.args`. An argument can have a default `value`. The Rollout supplies values when it starts the analysis. Inside the template, `{{ args.score }}` is replaced by the value before the measurement is taken. This allows one template to serve many Rollouts: each passes its own service name, address or threshold.

If a Rollout uses a template and does not give a value for an argument that has no default, the controller reports an error on the Rollout. Check the status message when a Rollout does not leave the phase `Progressing`.

## The web provider

The web provider sends an HTTP request and extracts one value from the JSON body of the answer with `jsonPath`. The path has the same form as a `kubectl` JSONPath, for example `{$.args.score[0]}`. The extracted text becomes `result` in the conditions.

```yaml
      provider:
        web:
          url: "http://httpbin.analysis.svc.cluster.local:8080/get?score={{ args.score }}"
          jsonPath: "{$.args.score[0]}"
```

In this course the endpoint is `go-httpbin`, a small server that echoes the request. The path `/get?score=95` answers with JSON that has the query parameters in the field `args`. The server returns the query values as lists, so `{$.args.score[0]}` selects the first value. A real team would point the template at a metrics API or at a service that computes a service level indicator. The mechanism stays the same.

The web provider can send headers, for example to carry a token. Keep tokens out of the template text: reference a Secret through the supported mechanism for the version of the controller you run and give the controller access to only that Secret.

## Conditions are expressions on the result

`result` is a value that you compare in an expression. The comparison `result == 'true'` works on text. A number arrives as text, so the template converts it before it compares:

```yaml
successCondition: asInt(result) >= 90
failureCondition: asInt(result) < 50
```

With only a `successCondition`, any measurement that does not meet it is a failure. With both conditions, a measurement that meets neither is inconclusive. The inconclusive state is useful when a value between two thresholds needs a decision by a person.

## What makes a good metric for a release

- The metric must differ between a good and a bad version. A metric that stays the same for both cannot stop anything.
- The metric must have data while the canary has low traffic. An error rate that is empty at a 5 percent share says nothing.
- The metric must be measured for the canary, not for the whole service. A good stable version can hide a bad canary.
- The measurement count and interval must cover the time that a defect needs to show. A single measurement of a slow leak is a pass.
- A missing value is not a pass. A metric that returns nothing must fail or be inconclusive, and the team must know which.

## Failure cases to recognise

- The endpoint cannot be reached: the measurement is an error, not a success. Repeated errors end the metric in the state `Error`.
- The path in `jsonPath` does not exist in the body: the measurement is an error.
- The condition is true for every input, for example `asInt(result) >= 0`: the gate always passes.
- The template name in the Rollout does not exist: the Rollout reports an error and the release does not start.
- The argument value is missing: the controller refuses to create the run.

## Common pitfalls

> [!WARNING]
> A template that measures the wrong thing passes a bad release with confidence. Choose metrics that change when the version is bad, and test the template against a known bad input before you trust it.
