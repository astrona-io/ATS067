---
draft: true
exam_objectives:
  - Progressive Delivery Patterns
---
# AnalysisTemplate And AnalysisRun Decisions

This module explains how a release asks a measurable question and uses the answer. You will read how an `AnalysisTemplate` defines a metric, how the web provider reads a value from an HTTP endpoint, how an `AnalysisRun` stores the results and what the controller does when a run fails. The hands-on steps use a kind cluster, the Argo Rollouts controller and `go-httpbin` as the measured endpoint.

## Learning Goals

- Separate an `AnalysisTemplate` (a definition) from an `AnalysisRun` (an execution).
- Write a metric with an interval, a count, a success condition and a failure limit.
- Explain how the web provider turns a JSON field into `result` and how arguments reach the URL.
- Place an analysis in a canary release as a background analysis or as an inline step.
- Read the phases `Successful`, `Failed`, `Inconclusive` and `Error` and predict what the Rollout does.
- Explain what an abort changes and what it leaves untouched.

## Before You Start

You should know what a Rollout, a canary step and a stable ReplicaSet are. The hands-on steps use a playground with `kubectl`. The Argo Rollouts kubectl plugin is not installed.

## Reading Order

1. AnalysisTemplate Metrics And The Web Provider
2. AnalysisRun Results And Aborting A Release
3. Summary

<!-- astrona:playground -->
