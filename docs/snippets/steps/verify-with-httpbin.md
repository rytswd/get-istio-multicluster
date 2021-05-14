# Verify with httpbin service

Assuming that you have httpbin service on target clusters, you can test the multicluster communication with that.

## With curl and interactive shell

<!-- == export: curl-httpbin-2-clusters / begin == -->

Simple `curl` to verify connection from `armadillo` to `bison`

```bash
kubectl exec \
    --context kind-armadillo \
    -n armadillo-offerings \
    -it \
    $(kubectl get pod \
        --context kind-armadillo \
        -n armadillo-offerings \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- curl -vvv httpbin.bison-offerings.global:8000/istio
```

<details>
<summary>Command to keep running curl against the endpoint</summary>

```bash
kubectl exec \
    --context kind-armadillo \
    -n armadillo-offerings \
    -it \
    $(kubectl get pod \
        --context kind-armadillo \
        -n armadillo-offerings \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- watch curl -vvv httpbin.bison-offerings.global:8000/istio
```

</details>

---

Simple `curl` to verify connection from `bison` to `armadillo`

```bash
kubectl exec \
    --context kind-bison \
    -n bison-offerings \
    -it \
    $(kubectl get pod \
        --context kind-bison \
        -n bison-offerings \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- curl -vvv httpbin.armadillo-offerings.global:8000/istio
```

<details>
<summary>Command to keep running curl against the endpoint</summary>

```bash
kubectl exec \
    --context kind-bison \
    -n bison-offerings \
    -it \
    $(kubectl get pod \
        --context kind-bison \
        -n bison-offerings \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- watch curl -vvv httpbin.armadillo-offerings.global:8000/istio
```

</details>

---

Interactive shell from Armadillo cluster

```bash
kubectl exec \
    --context kind-armadillo \
    -n armadillo-offerings \
    -it \
    $(kubectl get pod \
        --context kind-armadillo \
        -n armadillo-offerings \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c toolkit-alpine \
    -- bash
```

---

For logs

```bash
kubectl logs \
    --context kind-armadillo \
    -n armadillo-offerings \
    $(kubectl get pod \
        --context kind-armadillo \
        -n armadillo-offerings \
        -l app.kubernetes.io/name=toolkit-alpine \
        -o jsonpath='{.items[0].metadata.name}') \
    -c istio-proxy \
    | less
```

<details>
<summary>ℹ️ Details</summary>

`kubectl exec -it` is used to execute some command from the main container deployed from 4. Install Debug Processes.

The verification uses `curl` to connect from Armadillo's "toolkit" to Bison's "httpbin", or vice versa. The `curl` endpoint of `/istio` is not provided by httpbin Pod, but it is assumed that Istio VirtualService definition is created after following other steps. As long as Istio is configured and running correctly, this endpoint should be mapped to `httpbin/status/418` to give you a teapot response.

_TODO: More to be added_

<!-- The address here `httpbin.default.bison.global` is intentionally different from the Istio's official guidance of `httpbin.default.global`, as this would be important if you need to connect more than 2 clusters to form the mesh. This address of `httpbin.default.bison.global` can be pretty much anything you want, as long as you have the proper conversion logic defined in the target cluster - in this case Bison. -->

</details>

<!-- == export: curl-httpbin-2-clusters / end == -->
