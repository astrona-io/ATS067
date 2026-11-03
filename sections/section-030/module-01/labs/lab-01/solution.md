# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-030/module-01/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: Turn on prune and self-heal

```sh
kubectl -n argocd get application scout -o jsonpath='{.spec.syncPolicy}{"\n"}'
kubectl -n argocd patch application scout --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

The first command shows `automated` as an empty object. The patch fills it. Grade it; the check `sync-policy` passes.

## Step 2: Commit the change to Git

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/fleet-config.git
cd fleet-config
sed -i.bak 's/replicas: 2/replicas: 3/' apps/scout/deployment.yaml
rm apps/scout/deployment.yaml.bak apps/scout/old-flags.yaml
git add -A
git commit -m "scout: 3 replicas, remove old flags"
git push origin main
```

Argo CD finds the commit on its next refresh. To skip the wait, request one:

```sh
kubectl -n argocd annotate application scout argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd get application scout -w
```

The status becomes `OutOfSync`, then the automated sync starts. With `prune: true` the sync deletes the ConfigMap `old-flags`, because its file is gone from Git. The Deployment is scaled to 3 replicas. Check:

```sh
kubectl -n argocd get application scout -o jsonpath='{.status.sync.status} {.status.sync.revision}{"\n"}'
git rev-parse HEAD
kubectl -n starfleet get deployment scout
kubectl -n starfleet get configmap
```

The revision equals the output of `git rev-parse HEAD`. The ConfigMap `old-flags` is not in the list. Grade it; the check `git-change-applied` passes.

## Step 3: Watch self-heal and write the record

Change the live Deployment by hand and watch it return to the value in Git:

```sh
kubectl -n starfleet scale deployment scout --replicas=5
kubectl -n starfleet get deployment scout -w
```

After a short delay the controller applies the manifest from Git and the count returns to 3. This step is not graded, but it shows what `selfHeal` does. Then write the record:

```sh
kubectl -n starfleet create configmap sync-record \
  --from-literal=synced-revision="$(kubectl -n argocd get application scout -o jsonpath='{.status.sync.revision}')" \
  --from-literal=replicas="$(kubectl -n starfleet get deployment scout -o jsonpath='{.spec.replicas}')" \
  --from-literal=observed-at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

Wait until the replica count is 3 again before you write it. Grade the whole lab. All four checks pass.
