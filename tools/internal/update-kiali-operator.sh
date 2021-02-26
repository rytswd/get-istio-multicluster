#!/bin/bash

__tools_dir=$(dirname "$0")/..
__root_dir="$__tools_dir"/..

KIALI_OPERATOR_VERSION=1.30.0

for e in "armadillo" "bison"; do
    # Get into the directory for given cluster stack
    pushd "$__root_dir"/clusters/$e/observability/kiali/operator-install >/dev/null || {
        echo "failed to change directory"
        exit 1
    }

    # Run yq to update the YAML definition
    # Ref: https://github.com/mikefarah/yq
    # This step is using Docker container, so that as long as Docker is
    # available, this step can run in any env.
    docker run --rm -v "${PWD}":/workdir \
        mikefarah/yq eval ".dependencies[0].version = \"${KIALI_OPERATOR_VERSION}\"" \
        -i Chart.yaml

    # TODO: Consider updating the values.yaml as well

    # Get back to the original directory
    popd >/dev/null || {
        echo "failed to change directory"
        exit 1
    }
done
