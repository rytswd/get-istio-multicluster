# Deploy Debug Services

<!-- == export: for-2-clusters / begin == -->

```bash
{
    kubectl create namespace --context kind-armadillo armadillo-offerings
    kubectl label namespace --context kind-armadillo armadillo-offerings istio-injection=enabled
    kubectl apply --context kind-armadillo \
        -n armadillo-offerings \
        -f clusters/armadillo/other/httpbin.yaml \
        -f clusters/armadillo/other/color-svc-account.yaml \
        -f clusters/armadillo/other/color-svc-only-blue.yaml \
        -f clusters/armadillo/other/toolkit-alpine.yaml

    kubectl create namespace --context kind-bison bison-offerings
    kubectl label namespace --context kind-bison bison-offerings istio-injection=enabled
    kubectl apply --context kind-bison \
        -n bison-offerings \
        -f clusters/bison/other/httpbin.yaml \
        -f clusters/bison/other/color-svc-account.yaml \
        -f clusters/bison/other/color-svc-only-red.yaml \
        -f clusters/bison/other/toolkit-alpine.yaml
}
```

<details>
<summary>ℹ️ Details</summary>

There are 3 actions happening, and for 2 clusters (Armadillo and Bison).

Firstly, `kubectl create namespace` is called to create namespaces where the debug processes are being installed.

Secondly, `kubectl label namespace default istio-injection=enabled` marks that namespace (in this case `default` namespace) as Istio Sidecar enabled. This means any Pod that gets created in this namespace will go through Istio's MutatingWebhook, and Istio's Sidecar component (`istio-proxy`) will be embedded into the Pod. Without this setup, you will need to add Sidecar separately by running `istioctl` commands, which may be ok for testing, but certainly not scalable.

Third action is to install the testing tools.

- `httpbin` is a copy of httpbin.org, which can handle incoming HTTP request and return arbitrary output based on the input path.
- [`color-svc`](color-svc) is a simple web server which handles incoming HTTP request, and returns some random color. The configurations used in each cluster are slightly different, and produces different set of colors.
- [`toolkit-alpine`](toolkit-alpine) is a lightweight container which has a few tools useful for testing, such as `curl`, `dig`, etc.

For both `color-svc` and `toolkit-alpine`, [`tools`](https://github.com/rytswd/get-istio-multicluster/tree/main/tools) directory has the copy of the predefined YAML files. You can find more about how they are created in their repos.

- [github.com/rytswd/color-svc](color-svc)
- [github.com/rytswd/docker-toolkit-images](toolkit-alpine)

[color-svc]: https://github.com/rytswd/color-svc
[toolkit-alpine]: https://github.com/rytswd/docker-toolkit-images

</details>

<!-- == export: for-2-clusters / end == -->
