# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS067.git -c sections/section-040/module-02/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-running`.

## Step 1: Find the faulty commit and revert it

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000 &
git clone http://platform:starfleet-gitops@127.0.0.1:3000/starfleet/fleet-config.git
cd fleet-config
git log --oneline
kubectl -n scout-prod get deployment scout
git revert --no-edit $(git log --format=%H --grep='^prod: set replicas to 0$' -n 1)
git log --oneline
```

The log lists three commits and the Deployment in `scout-prod` shows no ready pods. `git revert` adds a fourth commit with the subject `Revert "prod: set replicas to 0"` and the line `This reverts commit <hash>.` in its body. The faulty commit stays in the history.

## Step 2: Promote the message in the prod overlay only

```sh
git diff HEAD~3 HEAD -- overlays/dev
sed -i.bak 's/value: release-1/value: release-2/' overlays/prod/kustomization.yaml
rm overlays/prod/kustomization.yaml.bak
kubectl kustomize overlays/prod
git commit -am "prod: message release-2"
```

The diff of the dev overlay shows the value that was tested. The rendered prod overlay shows `release-2` and 2 replicas. Nothing in `base` or in `overlays/dev` changes.

## Step 3: Push and wait

```sh
git push origin main
git rev-parse HEAD
kubectl -n argocd annotate application scout-dev scout-prod argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd get application scout-dev scout-prod
kubectl -n argocd get application scout-prod -o jsonpath='{.status.sync.revision}{"\n"}'
```

After the refresh both Applications are `Synced` at the commit that `git rev-parse` printed. The production Deployment has 2 pods with the new message. Grade the whole lab. All four checks pass.
