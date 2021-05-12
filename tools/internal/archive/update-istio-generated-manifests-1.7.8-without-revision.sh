#!/bin/bash

# This script is only meant to be used for 1.7.8 update without revision.
ISTIO_VERSION=1.7.8

# read -r -p "Which Istio version do you want to use? (e.g. 1.9.4, 1.10.0-rc.0): " selected_version
# if [[ $selected_version != "" ]]; then
#     ISTIO_VERSION=$selected_version
# fi

__tools_dir=$(dirname "$0")/../..
__root_dir="$__tools_dir"/..
# __revision=$(echo "$ISTIO_VERSION" | tr '.' '-')

__temp_dir=$(mktemp -d)
pushd "$__temp_dir" >/dev/null || {
    echo "failed to change directory"
    exit 1
}

echo "Getting istioctl based on Istio v$ISTIO_VERSION..."
{
    curl -sSL https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh - >/dev/null
}
PATH="$__temp_dir/istio-$ISTIO_VERSION/bin/:$PATH"
echo "  Complete."

popd >/dev/null || {
    echo "failed to change directory"
    exit 1
}

for e in "armadillo" "bison"; do
    echo "Running istioctl manifest generate for '$e' cluster..."

    target_dir="$__root_dir"/clusters/"$e"/istio/installation
    mkdir -p "$target_dir"
    pushd "$target_dir" >/dev/null || {
        echo "failed to change directory"
        exit 1
    }

    # Handle withtout-revision
    istioctl manifest generate \
        -f ./operator-usage/archive/1.7.8-specific/istio-control-plane.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./generated-manifests/"$ISTIO_VERSION"/without-revision/istio-control-plane-install.yaml
    istioctl manifest generate \
        -f ./operator-usage/archive/1.7.8-specific/istio-external-gateways.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./generated-manifests/"$ISTIO_VERSION"/without-revision/istio-external-gateways-install.yaml
    istioctl manifest generate \
        -f ./operator-usage/archive/1.7.8-specific/istio-multicluster-gateways.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./generated-manifests/"$ISTIO_VERSION"/without-revision/istio-multicluster-gateways-install.yaml
    istioctl manifest generate \
        -f ./operator-usage/archive/1.7.8-specific/istio-management-gateway.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./generated-manifests/"$ISTIO_VERSION"/without-revision/istio-management-gateway-install.yaml

    cat >./generated-manifests/"$ISTIO_VERSION"/without-revision/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./istio-control-plane-install.yaml
  - ./istio-external-gateways-install.yaml
  - ./istio-multicluster-gateways-install.yaml
  - ./istio-management-gateway-install.yaml
EOF

    # Copy relevant files from without-revision to without-revision-before-retiring
    cp ./generated-manifests/"$ISTIO_VERSION"/without-revision/*.yaml \
        ./generated-manifests/"$ISTIO_VERSION"/without-revision-before-retiring/
    mkdir ./generated-manifests/"$ISTIO_VERSION"/without-revision-before-retiring/patches
    cp ./references/patches/delete-duplicate-resources-control-plane-1.7.yaml \
        ./generated-manifests/"$ISTIO_VERSION"/without-revision-before-retiring/patches/delete-duplicate-resources-control-plane.yaml
    cat >./generated-manifests/"$ISTIO_VERSION"/without-revision-before-retiring/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./istio-control-plane-install.yaml
  - ./istio-external-gateways-install.yaml
  - ./istio-multicluster-gateways-install.yaml
  - ./istio-management-gateway-install.yaml

# Remove duplicated resources that are defined in the next canary release.
# Depending on the release, you may need to delete the duplicated resources
# from the newer release instead. In that case, the full installation spec
# should work.
patchesStrategicMerge:
  - ./patches/delete-duplicate-resources-control-plane.yaml
EOF

    echo "  Complete."

    popd >/dev/null || {
        echo "failed to change directory"
        exit 1
    }
done

# Clean up Istio installation
rm -rf "$__temp_dir"
