#!/bin/bash

__tools_dir=$(dirname "$0")/..
__root_dir="$__tools_dir"/..

JAEGER_OPERATOR_VERSION="v1.21.3"
JAEGER_OPERATOR_INSTALLATION_NAMESPACE="jaeger-operator"

for e in "armadillo" "bison" "dolphin"; do
    # Get into the directory for given cluster stack
    pushd "$__root_dir"/clusters/$e/observability/jaeger/operator-install >/dev/null || {
        echo "failed to change directory"
        exit 1
    }

    urlBase="https://raw.githubusercontent.com/jaegertracing/jaeger-operator/${JAEGER_OPERATOR_VERSION}/deploy/"

    # Download the installation definition
    curl -sSL "$urlBase/crds/jaegertracing.io_jaegers_crd.yaml" >./jaeger-operator-crds.yaml
    curl -sSL "$urlBase/service_account.yaml" >./jaeger-operator-service-account.yaml
    curl -sSL "$urlBase/role.yaml" >./jaeger-operator-role.yaml
    curl -sSL "$urlBase/role_binding.yaml" >./jaeger-operator-role-binding.yaml
    curl -sSL "$urlBase/cluster_role.yaml" >./jaeger-operator-cluster-role.yaml
    curl -sSL "$urlBase/cluster_role_binding.yaml" >./jaeger-operator-cluster-role-binding.yaml
    curl -sSL "$urlBase/operator.yaml" >./jaeger-operator-deployment.yaml

    # # Verify the file
    # shasum -a 256 ./jaeger-operator-crds.yaml
    # curl -sSL "$urlBase/crds/jaegertracing.io_jaegers_crd.yaml" | shasum -a 256
    # shasum -a 256 ./jaeger-operator-service-account.yaml
    # curl -sSL "$urlBase/service_account.yaml" | shasum -a 256
    # shasum -a 256 ./jaeger-operator-role.yaml
    # curl -sSL "$urlBase/role.yaml" | shasum -a 256
    # shasum -a 256 ./jaeger-operator-role-binding.yaml
    # curl -sSL "$urlBase/role_binding.yaml" | shasum -a 256
    # shasum -a 256 ./jaeger-operator-cluster-role.yaml
    # curl -sSL "$urlBase/cluster_role.yaml" | shasum -a 256
    # shasum -a 256 ./jaeger-operator-cluster-role-binding.yaml
    # curl -sSL "$urlBase/cluster_role_binding.yaml" | shasum -a 256
    # shasum -a 256 ./jaeger-operator-deployment.yaml
    # curl -sSL "$urlBase/operator.yaml" | shasum -a 256

    # Modify ClusterRoleBinidng target ServiceAccount namespace

    # Run yq to update the YAML definition
    # Ref: https://github.com/mikefarah/yq
    # This step is using Docker container, so that as long as Docker is
    # available, this step can run in any env.
    docker run --rm -v "${PWD}":/workdir \
        mikefarah/yq eval ".subjects[0].namespace = \"${JAEGER_OPERATOR_INSTALLATION_NAMESPACE}\"" \
        -i jaeger-operator-cluster-role-binding.yaml

    # Get back to the original directory
    popd >/dev/null || {
        echo "failed to change directory"
        exit 1
    }
done
