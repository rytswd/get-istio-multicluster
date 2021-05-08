#!/bin/bash

ISTIO_VERSION=1.9.4
read -r -p "Which Istio version do you want to use? (e.g. 1.9.4, 1.10.0-rc.0): " selected_version
if [[ $selected_version != "" ]]; then
    ISTIO_VERSION=$selected_version
fi

__tools_dir=$(dirname "$0")/..
__root_dir="$__tools_dir"/..
__revision=$(echo "$ISTIO_VERSION" | tr '.' '-')

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

for e in "armadillo" "bison" "dolphin"; do
    echo "Running istioctl manifest generate for '$e' cluster..."

    target_dir="$__root_dir"/clusters/"$e"/istio/installation
    mkdir -p "$target_dir"
    pushd "$target_dir" >/dev/null || {
        echo "failed to change directory"
        exit 1
    }

    # Prepare target directories
    mkdir -p ./generated-manifests/"$ISTIO_VERSION"/full-installation
    mkdir -p ./generated-manifests/"$ISTIO_VERSION"/as-canary
    mkdir -p ./generated-manifests/"$ISTIO_VERSION"/before-retiring

    # First, handle full installation
    istioctl manifest generate \
        --revision "$__revision" \
        -f ./operator-usage/istio-control-plane.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./generated-manifests/"$ISTIO_VERSION"/full-installation/istio-control-plane-install.yaml
    istioctl manifest generate \
        --revision "$__revision" \
        -f ./operator-usage/istio-external-gateways.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./generated-manifests/"$ISTIO_VERSION"/full-installation/istio-external-gateways-install.yaml
    istioctl manifest generate \
        --revision "$__revision" \
        -f ./operator-usage/istio-multicluster-gateways.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./generated-manifests/"$ISTIO_VERSION"/full-installation/istio-multicluster-gateways-install.yaml
    istioctl manifest generate \
        --revision "$__revision" \
        -f ./operator-usage/istio-management-gateway.yaml \
        -s values.global.jwtPolicy=first-party-jwt \
        >./generated-manifests/"$ISTIO_VERSION"/full-installation/istio-management-gateway-install.yaml

    cat >./generated-manifests/"$ISTIO_VERSION"/full-installation/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./istio-control-plane-install.yaml
  - ./istio-external-gateways-install.yaml
  - ./istio-multicluster-gateways-install.yaml
  - ./istio-management-gateway-install.yaml
EOF

    # Copy relevant files from full-installation to as-canary
    cp ./generated-manifests/"$ISTIO_VERSION"/full-installation/istio-control-plane-install.yaml \
        ./generated-manifests/"$ISTIO_VERSION"/as-canary/istio-control-plane-install.yaml
    cat >./generated-manifests/"$ISTIO_VERSION"/as-canary/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./istio-control-plane-install.yaml
EOF

    # Copy relevant files from full-installation to before-retiring
    cp ./generated-manifests/"$ISTIO_VERSION"/full-installation/*.yaml \
        ./generated-manifests/"$ISTIO_VERSION"/before-retiring/
    mkdir ./generated-manifests/"$ISTIO_VERSION"/before-retiring/patches
    cp ./references/patches/delete-duplicate-resources-control-plane.yaml \
        ./generated-manifests/"$ISTIO_VERSION"/before-retiring/patches/delete-duplicate-resources-control-plane.yaml
    cat >./generated-manifests/"$ISTIO_VERSION"/before-retiring/kustomization.yaml <<EOF
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
