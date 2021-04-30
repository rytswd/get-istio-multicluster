#!/bin/bash

ISTIO_VERSION=1.9.4

__tools_dir=$(dirname "$0")/..
__root_dir="$__tools_dir"/..
__revision=$(echo $ISTIO_VERSION | tr '.' '-')

__temp_dir=$(mktemp -d)
pushd "$__temp_dir" >/dev/null || {
    echo "failed to change directory"
    exit 1
}

echo "Installing Istio v$ISTIO_VERSION to get istioctl..."
{
    curl -sSL https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh - >/dev/null
}
PATH="$__temp_dir/istio-$ISTIO_VERSION/bin/:$PATH"
echo "  Complete."

popd >/dev/null || {
    echo "failed to change directory"
    exit 1
}

for e in "armadillo" "bison" "dolphin"; do
    echo "Running istioctl manifest generate for '$e' cluster..."

    target_dir="$__root_dir"/clusters/"$e"/istio/installation/no-operator-install/"$ISTIO_VERSION"
    mkdir "$target_dir"
    pushd "$target_dir" >/dev/null || {
        echo "failed to change directory"
        exit 1
    }

    istioctl manifest generate \
        --revision "$__revision" \
        -f ../../operator-usage/istio-control-plane.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./istio-control-plane-install.yaml
    istioctl manifest generate \
        --revision "$__revision" \
        -f ../../operator-usage/istio-external-gateways.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./istio-external-gateways-install.yaml
    istioctl manifest generate \
        --revision "$__revision" \
        -f ../../operator-usage/istio-multicluster-gateways.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./istio-multicluster-gateways-install.yaml
    istioctl manifest generate \
        --revision "$__revision" \
        -f ../../operator-usage/istio-management-gateway.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./istio-management-gateway-install.yaml

    cat >kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./istio-control-plane-install.yaml
  - ./istio-external-gateways-install.yaml
  - ./istio-multicluster-gateways-install.yaml
  - ./istio-management-gateway-install.yaml
EOF

    echo "  Complete."

    popd >/dev/null || {
        echo "failed to change directory"
        exit 1
    }
done

# Clean up Istio installation
rm -rf "$__temp_dir"
