# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/capstone/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: Projects and moves

```sh
for pair in dev-env:scout-dev prod-env:scout-prod; do
  proj="${pair%%:*}"; ns="${pair##*:}"
  kubectl apply -f - <<YAML
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: $proj
  namespace: argocd
spec:
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/fleet-config.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: $ns
  clusterResourceWhitelist: []
YAML
  kubectl -n argocd patch application "$ns" --type merge -p "{\"spec\":{\"project\":\"$proj\"}}"
done
kubectl -n argocd get application
```

The name of each Application equals the name of its namespace here, so the loop uses it twice. Each project allows its own namespace only, and each Application stays in its allowed destination, so neither shows a condition of the type `InvalidSpecError`. Grade it; the checks `projects-defined` and `apps-in-projects` pass.

## Step 2: Revert the faulty commit

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/fleet-config.git
cd fleet-config
git log --oneline
kubectl -n scout-prod get pods
git revert --no-edit $(git log --format=%H --grep='^prod: bump podinfo to 6.99.0$' -n 1)
```

The log shows three commits. The pod list of `scout-prod` shows a pod that cannot pull its image next to the old pods. The revert adds a commit with the line `This reverts commit <hash>.` and the faulty commit stays in the history.

## Step 3: Promote the message to the prod overlay

```sh
sed -i.bak 's/value: release-1/value: release-2/' overlays/prod/kustomization.yaml
rm overlays/prod/kustomization.yaml.bak
kubectl kustomize overlays/prod
git commit -am "prod: message release-2"
```

The rendered overlay shows `release-2` and the original image. Nothing in `base` or in `overlays/dev` changes.

## Step 4: Push and wait

```sh
git push origin main
git rev-parse HEAD
kubectl -n argocd annotate application scout-dev scout-prod argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd get application
```

After the refresh both Applications show the commit that `git rev-parse` printed, become `Synced` and, when the pods are ready, `Healthy`. Grade it; the checks `git-release` and `environments-reconciled` pass.

## Step 5: Record the release

```sh
kubectl -n scout-prod create configmap release-record \
  --from-literal=prod-revision="$(kubectl -n argocd get application scout-prod -o jsonpath='{.status.sync.revision}')" \
  --from-literal=prod-message="$(kubectl -n scout-prod get deployment scout -o jsonpath='{.spec.template.spec.containers[0].env[0].value}')"
```

The first environment variable of the container is `PODINFO_UI_MESSAGE`, so the second command reads the message. Grade the whole lab. All six checks pass.
