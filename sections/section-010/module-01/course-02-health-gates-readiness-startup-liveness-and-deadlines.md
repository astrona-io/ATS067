---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# Health Gates: Readiness, Startup, Liveness And Deadlines

A rolling update is only as safe as the test that decides a new pod is ready. If a pod counts as ready the moment its process starts, the controller removes old pods while the new ones still fail every request. Kubernetes uses probes to make that decision, and the Deployment adds two settings, `minReadySeconds` and `progressDeadlineSeconds`, that turn the probe results into rules for a rollout. This part explains each of them and shows a rollout that stalls.

## Three probes, three questions

A **probe** is a check that the kubelet runs against a container. The kubelet is the agent on each node that starts and watches containers. A probe is an HTTP request, a TCP connection, a gRPC call or a command run in the container. The three probe types answer different questions, and the kubelet acts differently on each answer.

The **readiness probe** asks whether the container can serve requests now. A failing readiness probe does not restart the container. It marks the pod as not ready, and the endpoints controller removes the pod from the Service endpoints, so the Service stops sending it traffic. A pod that is not ready also does not count as available for the Deployment.

The **liveness probe** asks whether the container is still working or has hung. When it fails more often than `failureThreshold` allows, the kubelet kills the container and restarts it according to the pod `restartPolicy`. A wrong liveness probe therefore produces restart loops, and a restart loop looks like a crashing application even when the application is fine.

The **startup probe** asks whether the application has finished starting. While it has not succeeded, the kubelet does not run the liveness or the readiness probe. This protects a slow application from being killed by a liveness probe that is tuned for normal operation. When the startup probe fails for too long, the kubelet restarts the container.

The consequence for a rollout is direct. Only the readiness probe decides whether a new pod receives traffic and whether the Deployment counts it as available. A pod can be `Running` and still not be ready. Always check the `READY` column and not only the `STATUS` column.

## What the probe fields mean

All three probes share a set of timing fields. `initialDelaySeconds` is the wait before the first check. `periodSeconds` is the time between checks. `timeoutSeconds` is how long one check may take. `successThreshold` and `failureThreshold` are the number of consecutive successes and failures that change the state. For a readiness probe with `periodSeconds: 5` and `failureThreshold: 3`, a broken application is taken out of the Service after about 15 seconds.

The check itself must test what users need. A path that always answers `200` once the web server runs proves that the process started and nothing else. A better readiness endpoint returns success only when the application can reach what it needs, for example its database connection. It must not depend on shared services in a way that makes every replica fail at the same time, because then all pods leave the Service together.

## minReadySeconds and the available state

A pod becomes **ready** when its readiness probe succeeds. A pod becomes **available** when it has been ready for `minReadySeconds` without any of its containers crashing. The default of `minReadySeconds` is 0, so ready and available coincide. The rolling update counts available pods when it applies `maxUnavailable`.

Set `minReadySeconds` to 10 and the controller waits 10 seconds of stable readiness before it removes the next old pod. This catches an application that passes its first readiness check and crashes a few seconds later. It slows every rollout by the same amount per step, so choose a value that matches how long a defect takes to show.

## progressDeadlineSeconds and a stalled rollout

The field `spec.progressDeadlineSeconds` sets how long the Deployment controller waits for progress before it reports a failure. The default is 600 seconds. Progress means that a new ReplicaSet was created, a ReplicaSet scaled up or a pod became ready. When no progress happens for that time, the controller sets the condition `Progressing` to `False` with the reason `ProgressDeadlineExceeded`.

This condition is a report. The controller does not roll back and does not scale the new ReplicaSet down. The stalled pods keep trying, and the old pods keep serving, because `maxUnavailable` stopped the controller from removing them. The `kubectl rollout status` command reads the condition and exits with an error. A pipeline can use that exit code to decide on a rollback, and the decision stays outside Kubernetes.

## Make a rollout stall

<!-- astrona:playground:renew -->

The playground cluster has the Deployment `scout` with 4 ready replicas. First set a short deadline, so that you do not wait ten minutes:

```sh
kubectl -n starfleet patch deployment scout --type=merge -p '{"spec":{"progressDeadlineSeconds":30}}'
```

Now start a rollout to an image tag that does not exist. The container runtime cannot pull it, so the new pod never starts:

```sh
kubectl -n starfleet set image deployment/scout scout=ghcr.io/stefanprodan/podinfo:0.0.0-missing
kubectl -n starfleet get pods -l app=scout
```

The list shows the 4 old pods running and one new pod in a state such as `ErrImagePull` or `ImagePullBackOff`. The Deployment created one new pod because `maxSurge` is 1, and it cannot remove an old pod because `maxUnavailable` is 0 and the new pod is not available. The old pods keep serving every request.

Wait for the deadline and read the status:

```sh
kubectl -n starfleet rollout status deployment/scout --timeout=90s
kubectl -n starfleet get deployment scout -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
```

The status command reports that the deployment exceeded its progress deadline and exits with a non-zero code. The condition list shows `Progressing=False` with the reason `ProgressDeadlineExceeded`. The `Available` condition stays `True`, because the old pods still serve. The condition `Available` and the condition `Progressing` answer different questions: whether the application serves now, and whether the rollout moves.

## A readiness failure looks different

Replace the image problem with a readiness problem. Point the readiness probe at a path that does not exist, with the correct image. The pod starts, the container runs, and the readiness probe fails on every check because the path answers `404`:

```sh
kubectl -n starfleet set image deployment/scout scout=ghcr.io/stefanprodan/podinfo:6.15.0
kubectl -n starfleet patch deployment scout --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/no-such-path"}]'
kubectl -n starfleet get pods -l app=scout
```

The new pod is `Running` with `0/1` in the `READY` column. The status says running, and the pod is still not in the Service. Use `kubectl describe pod` on the new pod and read the events: they show `Readiness probe failed` with the HTTP status code. The cause is in the probe configuration, not in the image, and the fix differs from the fix for the image problem.

Compare the two failures. With an unpullable image, the container never starts, and the event names the pull error. With a failing readiness probe, the container runs and the probe event shows the status code. Reading the pod events first tells you which of the two you face, before you change anything.

## Probe settings that suit a rollout

A good rollout configuration states the gates in the pod template, so that every revision carries them. The fragment below shows the fields that matter. The readiness probe tests the application path `/readyz` every 5 seconds and removes the pod after 3 failures. The startup probe gives the application up to 30 checks of 2 seconds each, which is 60 seconds, to start before the other probes begin.

```yaml
spec:
  minReadySeconds: 10
  progressDeadlineSeconds: 120
  template:
    spec:
      containers:
        - name: scout
          readinessProbe:
            httpGet: {path: /readyz, port: http}
            periodSeconds: 5
            failureThreshold: 3
          startupProbe:
            httpGet: {path: /healthz, port: http}
            periodSeconds: 2
            failureThreshold: 30
```

The `minReadySeconds` and `progressDeadlineSeconds` fields belong to the Deployment `spec`. The probes belong to the container in the pod template. Changing a probe changes the template, so it starts a rollout. Changing `minReadySeconds` or `progressDeadlineSeconds` does not change the template and does not start one.

You have seen that probes decide availability, that `minReadySeconds` adds a stability window and that `progressDeadlineSeconds` only reports a stall. The open question is what to do once a rollout has stalled. Reverting to the previous revision is the usual answer, and what it does and does not restore is the next topic.

## Common pitfalls

> [!WARNING]
> A pod that is `Running` is not necessarily ready. `ProgressDeadlineExceeded` does not roll back. A liveness probe that is stricter than the application can handle restarts healthy containers. A readiness check that tests a shared dependency can remove every replica from the Service at once.
