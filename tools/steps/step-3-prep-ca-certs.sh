#!/bin/bash

{
    pushd certs >/dev/null
    make -f ../tools/certs/Makefile.selfsigned.mk root-ca

    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk dolphin-cacerts

    popd >/dev/null

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

    kubectl create namespace --context kind-dolphin istio-system
    kubectl create secret --context kind-dolphin \
        generic cacerts -n istio-system \
        --from-file=./certs/dolphin/ca-cert.pem \
        --from-file=./certs/dolphin/ca-key.pem \
        --from-file=./certs/dolphin/root-cert.pem \
        --from-file=./certs/dolphin/cert-chain.pem
}
