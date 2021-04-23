# Install Istio Operator

## Using `istioctl`

<!-- == export: istio-operator-with-istioctl / begin == -->

> 📝 **NOTE**:  
> This will install Istio version based on `istioctl` version you have on your machine. You will need to manage your `istioctl` version separately, or you could take manifest generation approach instead, which is based on declarative and static definitions.

```bash
{
    istioctl --context kind-armadillo \
        operator init \
        -f ./clusters/armadillo/istio/installation/operator-install/istio-operator-install.yaml

    istioctl --context kind-bison \
        operator init \
        -f ./clusters/bison/istio/installation/operator-install/istio-operator-install.yaml
}
```

<!-- == export: istio-operator-with-istioctl / end == -->

## Using manifest

<!-- == export: istio-operator-with-manifest-generation / begin == -->

```bash
{
    kubectl apply --context kind-armadillo \
        -f ./clusters/armadillo/istio/installation/operator-install/istio-operator-install.yaml

    kubectl apply --context kind-bison \
        -f ./clusters/bison/istio/installation/operator-install/istio-operator-install.yaml
}
```

When you see error messages such as:

```console
Error from server (NotFound): error when creating "./clusters/armadillo/istio/installation/operator-install/istio-operator-install.yaml": namespaces "istio-operator" not found
```

You can simply run the above command one more time. <!--TODO: Add more details-->

<!-- == export: istio-operator-with-manifest-generation / end == -->

## What is Istio Operator install

<!-- == export: istio-operator-details / begin == -->

This prepares for Istio installation by installing IstioOperator Controller. It allows defining IsitoOperator Custom Resource in declarative manner, and IstioOperator Controller to handle the installation.

You can use `istioctl operator init` to install, or get the IstioOperator Controller installation spec with `istioctl operator dump`. In multicluster scenario, it is safer to have all clusters with the same Istio version, and thus you could technically use the same spec.

As this repository aims to be as declarative as possible, the installation specs are saved using `istioctl operator dump`, and saved under each cluster spec. You can use `get-istio-multicluster/tools/internal/update-istio-operator-install.sh` script to update all the IstioOperator Controller installation spec in one go.

<!-- == export: istio-operator-details / end == -->
