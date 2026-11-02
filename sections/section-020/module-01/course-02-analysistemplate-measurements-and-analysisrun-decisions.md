---
draft: true
exam_objectives:
- Progressive Delivery Patterns
---
# AnalysisTemplate Measurements And AnalysisRun Decisions

Analysis adds measured evidence to progressive-delivery decisions. An AnalysisTemplate defines metrics, provider queries and conditions, while an AnalysisRun represents one execution with concrete inputs and results. Understanding this distinction helps explain why a rollout advanced, failed or paused without equating a single numeric threshold with complete release safety.

## Definitions And Runs Have Different Lifecycles

A reusable template specifies what should be measured and how results should be interpreted. A run supplies arguments and records measurement outcomes under that definition. Multiple runs can use the same template with different candidate versions or service contexts.

Record which definition and inputs were used when assessing a result. A template edited later does not prove an earlier run evaluated the new criteria. Invocation authority and template-editing authority should also be reviewed separately because changing the definition can change future promotion decisions.

## Providers Supply Evidence

Supported providers can query metrics or perform other configured measurements. Arguments can identify stable and canary populations, namespaces or service names. The query must select the intended release and time window. A fleet-wide metric that mostly reflects the stable version can hide a candidate failure.

Provider access needs credentials, network connectivity and appropriate permissions. A query error can reflect unavailable observation rather than application failure. Conversely, a successful query can return irrelevant or insufficient data. Validate the measurement contract before interpreting the result.

## Conditions Turn Results Into Decisions

Success and failure conditions describe how measurements are classified. Supported limits, intervals and counts determine how repeated observations affect the run. Error and inconclusive states need deliberate handling rather than being assumed equivalent to success or a proven regression.

An empty metric result can mean low traffic, missing instrumentation or broken selection. Treating it as zero failures can promote a candidate with no useful evidence. Define the minimum meaningful observation and the response when that evidence is unavailable. Percentages also need a relevant denominator and sufficient volume.

## Placement Changes What Is Tested

Analysis can run at selected steps or in supported background arrangements. A pre-promotion measurement sees a different population from a measurement after broad exposure. The chosen placement should match the risk being assessed and the amount of candidate traffic available.

A short observation window can react quickly but be noisy, while a long window can delay a decision or mix data from earlier versions. Stable label identity and suitable query windows are necessary to attribute the measurement to the current candidate.

## Interpret The Rollout Response

The Rollout controller uses analysis results according to its strategy. A failed or inconclusive run can lead to different progression behavior. Review the run's status, measurement detail and configured response rather than infer the reason from the rollout's final color alone.

Analysis cannot reverse external side effects. Aborting exposure may stop additional candidate traffic while leaving writes, migrations or leaked credentials to address separately. Preserve results for diagnosis and distinguish a measured regression from a provider outage. A useful analysis design supplies bounded, relevant evidence and an explicit response for every meaningful outcome.

## Common pitfalls

> [!WARNING]
> Empty or failed queries are not automatic release success. AnalysisTemplate and AnalysisRun have different lifecycles, and provider evidence, population selection and progression response must agree.
