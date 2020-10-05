# Simple Istio Multicluster

Istio Multicluster is by no means simple. This repository tries to show involved example, but with simple configurations.

## Clusters

The directories here are some clusters.


### `armadillo`: cluster with shared Istio Control Plane (with `crocodile`)


### `bison`: cluster with dedicated Istio Control Plane


### `crocodile`: clustter with shared Istio Control Plane (with `armadillo`)


### `dolphin`: cluster with dedicated Istio Control Plane


### `zebra`: cluster without Istio, as external cluster


## Tools

### `httpbin` 

```bash
$ kubectl label namespace default istio-injection=enabled
$ kubectl apply -f tools/httpbin/httpbin.yaml
```

### `toolkit-alpine`

```bash
$ kubectl label namespace default istio-injection=enabled
$ kubectl apply -f tools/toolkit-alpine/toolkit-alpine.yaml
```
