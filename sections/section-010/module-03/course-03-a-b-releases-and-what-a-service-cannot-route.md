---
draft: true
exam_objectives:
  - Deployment and Release Patterns
---
# A/B Releases And What A Service Cannot Route

A canary release asks whether a new version is safe. An A/B release asks a different question: which of two versions gives the better result for the people who use it. Both send some users to the new version, so they look the same from outside, but they differ in who is chosen, how long the test runs and what decides the winner. This part defines the difference, shows that a Kubernetes Service cannot route by user rule, and lists the components that can.

## Canary and A/B compared

A canary release exposes a random, small share of traffic to the new version for a short time. The team looks for errors, latency and resource use. If these are fine, the share grows until it reaches 100 percent. The goal is safety, and the version that passes replaces the old one.

An A/B release assigns users to a group by a rule, for example by an HTTP header, a cookie or a user identifier, and keeps the groups apart for as long as the experiment needs. The team compares a business measurement between the groups, for example the share of visits that end in a purchase. The goal is a decision about the product, and both versions may stay in production during the test.

Two properties matter. The assignment must be sticky, which means the same user always reaches the same version, or the measurement is mixed up. And the groups must be comparable, so that a difference in the result comes from the version and not from the type of user in each group.

## What a Service routes by

A Service sends each new connection to one ready endpoint of its selector. The decision uses no information from the request: not a header, not a cookie, not the path and not the source address by default. The component that does this, `kube-proxy` on each node, works at the connection level, before any HTTP request is read.

The playground has two Deployments, `scout-a` and `scout-b`. They return the messages `a` and `b`. The Service `scout` selects both, and the Services `scout-a` and `scout-b` select one each. Define the helper once in the terminal:

<!-- astrona:playground:renew -->

```sh
count_messages() {
  kubectl -n starfleet exec deploy/shuttle -- sh -c "for i in \$(seq 1 $2); do curl -s $3 http://$1:9898/ | grep -o '\"message\": *\"[a-z]*\"'; done | sort | uniq -c"
}
```

Send 20 requests that carry a header to the Service `scout`:

```sh
count_messages scout 20 "-H X-Beta-User:true"
```

Both messages appear in the counts. The header `X-Beta-User` is sent to the pods, but the Service never reads it. A request with the header is as likely to reach `a` as a request without it. Repeat it with a different header value and the split stays the same.

## Sticky assignment with a Service

A Service has one setting that comes near to stickiness: `spec.sessionAffinity: ClientIP`. It sends all connections from the same client address to the same pod for a timeout of 10800 seconds by default. Read the field on the Service:

```sh
kubectl -n starfleet get service scout -o jsonpath='{.spec.sessionAffinity}{"\n"}'
```

The value is `None`. The setting works on the source address, which is the address of a node or a proxy in many clusters, so many users share one address and the assignment is not per user. It is not a way to run an A/B test. It only keeps a client on one pod.

## Components that route by request

Routing by request content needs a component that reads the HTTP request. Four kinds are common.

- An ingress controller reads the Ingress resource and routes by host and path. Some controllers add annotations for headers, cookies and weights, and the annotations differ from controller to controller.
- A gateway that implements the Gateway API routes with an `HTTPRoute` resource. A rule in it can match a header, a path or a query parameter, and can send a weighted share to each backend.
- A service mesh such as Istio routes inside the cluster with its own resources, for example a `VirtualService`, and can match headers and set weights between versions.
- The application itself can pick the version, for example by calling a different back end for users in a flag-selected group.

A weight in these components is a share of requests, not of pods. The share of 5 percent needs no 95 stable pods. The router counts requests, so the pod counts and the weights are independent.

## Two Deployments behind the router

The Kubernetes objects below the router stay the same as in the earlier patterns. Each version has its own Deployment and its own Service, here `scout-a` and `scout-b`. The router then sends each request to one of the two Services by its rule. Check that each version answers on its own Service:

```sh
count_messages scout-a 5
count_messages scout-b 5
```

Only `a` appears for the first command and only `b` for the second. This is the layout a router needs: one stable name per version. A router rule that matches `X-Beta-User: true` would send those requests to `scout-b` and the others to `scout-a`.

## Reading the result of an experiment

A difference between two groups can be chance. A test needs enough users in each group, and the team must decide the size and the duration before the test, so that it does not stop on the first good-looking number. Stopping early on a lucky difference is a common mistake and gives wrong decisions.

The groups must also be exposed to the same conditions. If group B only receives requests from one region, a difference may come from the region. Random assignment on a stable key avoids this.

The experiment should have a stop condition for harm, as a canary does. A version that raises the error rate must be removed from the experiment at once, whatever the business number says.

You now know that an A/B release needs routing by request content, which a Service does not offer, and that it has a different goal from a canary. The open question is how to test a version against real traffic when no user may see its answers, which is the job of shadow traffic.

## Common pitfalls

> [!WARNING]
> A Service ignores headers, cookies and paths, and `sessionAffinity: ClientIP` keys on the source address, not on the user. A weight set by pod counts is not an A/B assignment. Do not call a test an A/B test when users can move between versions.
