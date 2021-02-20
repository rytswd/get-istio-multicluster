#!/bin/bash

# For Armadillo configuration
{
    echo "Starting Armadillo config files update..."

    ARMADILLO_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc \
        --context kind-armadillo \
        -n istio-system \
        istiocoredns \
        -o jsonpath={.spec.clusterIP})
    echo "$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP"

    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$ARMADILLO_ISTIOCOREDNS_CLUSTER_IP/" \
        clusters/armadillo/istio/for-demo-2/coredns-configmap.yaml

    ARMADILLO_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=armadillo-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    echo "$ARMADILLO_EGRESS_GATEWAY_ADDRESS"
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/istio/for-demo-2/bison-color-svc.yaml
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$ARMADILLO_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/armadillo/istio/for-demo-2/bison-httpbin.yaml

    BISON_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-bison \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    echo "$BISON_INGRESS_GATEWAY_ADDRESS"
    {
        sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
            clusters/armadillo/istio/for-demo-2/bison-color-svc.yaml
        if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32022/" \
                clusters/armadillo/istio/for-demo-2/bison-color-svc.yaml
        fi
        sed -i '' -e "s/REPLACE_WITH_BISON_INGRESS_GATEWAY_ADDRESS/$BISON_INGRESS_GATEWAY_ADDRESS/g" \
            clusters/armadillo/istio/for-demo-2/bison-httpbin.yaml
        if [[ $BISON_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32022/" \
                clusters/armadillo/istio/for-demo-2/bison-httpbin.yaml
        fi
    }

    echo "  Complete."
}

# For Bison configuration
{
    echo "Starting Bison config files update..."

    BISON_ISTIOCOREDNS_CLUSTER_IP=$(kubectl get svc \
        --context kind-bison \
        -n istio-system \
        istiocoredns \
        -o jsonpath={.spec.clusterIP})
    echo "$BISON_ISTIOCOREDNS_CLUSTER_IP"

    sed -i '' -e "s/REPLACE_WITH_ISTIOCOREDNS_CLUSTER_IP/$BISON_ISTIOCOREDNS_CLUSTER_IP/" \
        clusters/bison/istio/for-demo-2/coredns-configmap.yaml

    BISON_EGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-bison \
        -n istio-system \
        --selector=app=bison-multicluster-egressgateway \
        -o jsonpath='{.items[0].spec.clusterIP}')
    echo "$BISON_EGRESS_GATEWAY_ADDRESS"
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$BISON_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/bison/istio/for-demo-2/armadillo-color-svc.yaml
    sed -i '' -e "s/REPLACE_WITH_EGRESS_GATEWAY_CLUSTER_IP/$BISON_EGRESS_GATEWAY_ADDRESS/g" \
        clusters/bison/istio/for-demo-2/armadillo-httpbin.yaml

    ARMADILLO_INGRESS_GATEWAY_ADDRESS=$(kubectl get svc \
        --context=kind-armadillo \
        -n istio-system \
        --selector=app=istio-ingressgateway \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '172.18.0.1')
    echo "$ARMADILLO_INGRESS_GATEWAY_ADDRESS"
    {
        sed -i '' -e "s/REPLACE_WITH_ARMADILLO_INGRESS_GATEWAY_ADDRESS/$ARMADILLO_INGRESS_GATEWAY_ADDRESS/g" \
            clusters/bison/istio/for-demo-2/armadillo-color-svc.yaml
        if [[ $ARMADILLO_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32022/" \
                clusters/bison/istio/for-demo-2/armadillo-color-svc.yaml
        fi
        sed -i '' -e "s/REPLACE_WITH_ARMADILLO_INGRESS_GATEWAY_ADDRESS/$ARMADILLO_INGRESS_GATEWAY_ADDRESS/g" \
            clusters/bison/istio/for-demo-2/armadillo-httpbin.yaml
        if [[ $ARMADILLO_INGRESS_GATEWAY_ADDRESS == '172.18.0.1' ]]; then
            sed -i '' -e "s/15443 # Istio Ingress Gateway port/32022/" \
                clusters/bison/istio/for-demo-2/armadillo-httpbin.yaml
        fi
    }

    echo "  Complete."
}
