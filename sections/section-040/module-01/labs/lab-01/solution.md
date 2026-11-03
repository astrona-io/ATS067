# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/module-01/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: Create the project

```sh
kubectl -n argocd get appproject
kubectl apply -f - <<'YAML'
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: crew
  namespace: argocd
spec:
  description: Applications of the crew team
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: starfleet
  clusterResourceWhitelist: []
YAML
kubectl -n argocd get appproject crew -o yaml
```

The list `destinations` has one entry, and `clusterResourceWhitelist` is empty, so no cluster-scoped kind is allowed. Before the change, only `default` and no `crew` exists. Grade it; the check `project-defined` passes.

## Step 2: Move scout

```sh
kubectl -n argocd patch application scout --type merge -p '{"spec":{"project":"crew"}}'
kubectl -n argocd annotate application scout argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd get application scout
```

The destination of `scout` is the namespace `starfleet` on the in-cluster server and the repository is the one in `sourceRepos`, so the project allows it. The Application stays `Synced` and `Healthy`. Grade it; the check `scout-in-project` passes.

## Step 3: Move intruder

```sh
kubectl -n argocd patch application intruder --type merge -p '{"spec":{"project":"crew"}}'
kubectl -n argocd annotate application intruder argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd get application intruder -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.message}{"\n"}{end}'
```

The destination of `intruder` is the namespace `vault`. The project allows only `starfleet`, so the controller sets a condition of the type `InvalidSpecError` and stops syncing the Application. Read the message to see which destination is refused. The ConfigMap that was deployed earlier stays in `vault`, because a project does not delete live objects. Grade the whole lab. All four checks pass.
