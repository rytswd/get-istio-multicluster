# Certificate Preparation

## Create Certificate using Istio's Certificate generation Makefile

<!-- == export: prep-certs-with-local-ca / begin == -->

The first step is to generate the certificates.

```bash
{
    pushd certs > /dev/null
    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts

    popd > /dev/null
}
```

<details>
<summary>ℹ️ Details</summary>

Creating certificates uses Istio's certificate creation setup.

You can find the original documentation [here](https://github.com/istio/istio/tree/master/tools/certs) (or [here for v1.9.2](https://github.com/istio/istio/tree/1.9.2/tools/certs)).

```bash
{
    # Get into certs directory
    pushd certs > /dev/null

    # Create Root CA, which would then be used to sign Intermediate CAs.
    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    # Create Intermediate CA for each cluster. All clusters have their own
    # certs for security reason. These certs are signed by the above Root CA.
    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts

    # Get back to previous directory
    popd > /dev/null
}
```

</details>

<!-- == export: prep-certs-with-local-ca / end == -->

## Create Kubernetes Secrets with above certificates

<!-- == export: prep-kubernetes-secrets / begin == -->

The second step is to create Kubernetes Secrets holding the generated certificates in the correpsonding clusters.

```bash
{
    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./certs/armadillo/ca-cert.pem \
        --from-file=./certs/armadillo/ca-key.pem \
        --from-file=./certs/armadillo/root-cert.pem \
        --from-file=./certs/armadillo/cert-chain.pem

    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./certs/bison/ca-cert.pem \
        --from-file=./certs/bison/ca-key.pem \
        --from-file=./certs/bison/root-cert.pem \
        --from-file=./certs/bison/cert-chain.pem
}
```

<details>
<summary>ℹ️ Details</summary>

If you do not create the certificate before Istio is installed to the cluster, Istio will fall back to use its own certificate. This will cause an issue when you try to use your custom cert later on. It's best to get the cert ready first - otherwise you will likely need to run through a bunch of restarts of Istio components and others to ensure the correct cert is picked up. This will also likely require inevitable downtime.

As of writing (April 2021), there is some work being done on Istio to provide support for multiple Root certificates.

Ref: https://github.com/istio/istio/issues/31111

Each command used above is associated with some comments to clarify what they do:

```bash
{
    # Create a secret `cacerts`, which is used by Istio.
    # Istio's component `istiod` will use this, and if there is no secret in
    # place before `istiod` starts up, it would fall back to use Istio's
    # default CA which is only menat to be used for testing.
    #
    # The below commands are for Armadillo cluster.
    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./certs/armadillo/ca-cert.pem \
        --from-file=./certs/armadillo/ca-key.pem \
        --from-file=./certs/armadillo/root-cert.pem \
        --from-file=./certs/armadillo/cert-chain.pem
    #
    # The below commands are for Bison cluster.
    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./certs/bison/ca-cert.pem \
        --from-file=./certs/bison/ca-key.pem \
        --from-file=./certs/bison/root-cert.pem \
        --from-file=./certs/bison/cert-chain.pem
}
```

</details>

<!-- == export: prep-kubernetes-secrets / end == -->

## Delete created certificates

<!-- == export: delete-certs / begin == -->

Provided that you are using some clone of this repo, you can run the following to remove certs.

```bash
{
    rm -rf certs
    git checkout certs --force
}
```

<details>
<summary>ℹ️ Details</summary>

Remove the entire `certs` directory, and `git checkout certs --force` to remove all the changes.

If you are simply pulling the files without Git, you can run:

```bash
{
    rm -rf certs
    mkdir certs
}
```

</details>

<!-- == export: delete-certs / end == -->
