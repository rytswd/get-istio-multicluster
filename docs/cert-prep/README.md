# Certificate Preparation

**NOTE**: This document is work in progress.  
For now, you can run the following command:

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ {
    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./sample-certs/ca-cert.pem \
        --from-file=./sample-certs/ca-key.pem \
        --from-file=./sample-certs/root-cert.pem \
        --from-file=./sample-certs/cert-chain.pem
    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./sample-certs/ca-cert.pem \
        --from-file=./sample-certs/ca-key.pem \
        --from-file=./sample-certs/root-cert.pem \
        --from-file=./sample-certs/cert-chain.pem
}
```

This is NOT appropriate for production usage.

## Prerequisites

- openssl

## Steps

### 0. Prepare CA Certs

```bash
$ pwd
/some/path/at/simple-istio-multicluster

$ mkdir /tmp/istio-input/
```

<details>
<summary>Details</summary>

_To be updated_

</details>

---

### 1. Client cert prep

```bash
$ {
    openssl genrsa -out /tmp/istio-input/client-tls.key 2048
    openssl req \
        -new \
        -sha256 \
        -days 365 \
        -config ./ext.config \
        -key /tmp/istio-input/client-tls.key \
        -out /tmp/istio-input/client-tls.csr \
        -subj "/C=GB/ST=London/L=London/O=Some Dev Inc./OU=Some Dev Client/CN=some.dev"
}
```

<details>
<summary>Details</summary>

_To be updated_

</details>

---

### 2. Root CA prep

```bash
$ {
    openssl genrsa -des3 -out /tmp/istio-input/root-ca-passphrase.key 4096
    openssl req \
        -new \
        -x509 \
        -days 365 \
        -config ext.config \
        -key /tmp/istio-input/root-ca-passphrase.key \
        -out /tmp/istio-input/root-ca.crt \
        -subj "/C=GB/ST=London/L=London/O=Some Dev Inc./OU=Some Dev Root CA/CN=some.dev"
    openssl rsa \
        -in /tmp/istio-input/root-ca-passphrase.key \
        -out /tmp/istio-input/root-ca.key
}
```

<details>
<summary>Details</summary>

_To be updated_

</details>

---

### 3. Intermediate CA prep

```bash
$ {
    openssl genrsa -des3 -out /tmp/istio-input/intermediate-ca-passphrase.key 4096
    openssl req \
        -new \
        -sha256 \
        -config ext.config \
        -key /tmp/istio-input/intermediate-ca-passphrase.key \
        -out /tmp/istio-input/intermediate-ca.csr \
        -subj "/C=GB/ST=London/L=London/O=Some Dev Inc./OU=Some Dev Intermediate CA/CN=some.dev"
    openssl ca \
        -config ext.config \
        -extensions v3_intermediate_ca \
        -days 2650 \
        -notext \
        -batch \
        -in /tmp/istio-input/intermediate-ca.csr \
        -out /tmp/istio-input/intermediate-ca.crt
}
```

<details>
<summary>Details</summary>

Verification

```bash
openssl x509 -noout -text -in /tmp/istio-input/intermediate-ca.crt
```

_To be updated_

</details>

---

### 3. Sign Client CA

```bash
{
    openssl x509 \
        -req \
        -sha256 \
        -days 365 \
        -CA /tmp/istio-input/root-ca.crt \
        -CAkey /tmp/istio-input/root-ca.key \
        -CAcreateserial \
        -extfile ext.config \
        -extensions client_cert \
        -in /tmp/istio-input/client-tls.csr \
        -out /tmp/istio-input/client-tls.crt
}
```

<details>
<summary>Details</summary>

- Armadillo will set up Istio IngressGateway with 32001 NodePort
- Bison will set up Istio IngressGateway with 32002 NodePort

</details>

---