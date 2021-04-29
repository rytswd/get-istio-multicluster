# Certificate Preparation

⚠️ This page is WIP ⚠️

## Prerequisites

- openssl

## Steps

This step uses a makefile definition from Istio repository.

Ref: https://github.com/istio/istio/tree/master/tools/certs

### 1. Create Root CA

```bash
$ pwd
/some/path/at/get-istio-multicluster

$ cd certs
/some/path/at/get-istio-multicluster/certs

$ make -f ../tools/certs/Makefile.selfsigned.mk root-ca
```

---

### 2. Create Intermediate CA for each cluster

```bash
$ {
    make -f ../tools/certs/Makefile.selfsigned.mk armadillo-cacerts
    make -f ../tools/certs/Makefile.selfsigned.mk bison-cacerts
}
```

---

### 3. Create Kubernetes Secrets

```bash
$ {
    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=./armadillo/ca-cert.pem \
        --from-file=./armadillo/ca-key.pem \
        --from-file=./armadillo/root-cert.pem \
        --from-file=./armadillo/cert-chain.pem

    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=./bison/ca-cert.pem \
        --from-file=./bison/ca-key.pem \
        --from-file=./bison/root-cert.pem \
        --from-file=./bison/cert-chain.pem
}
```

---

## Steps (Detailed Commands)

_TODO: To be corrected, the below won't work correctly_

```bash
$ pwd
/some/path/at/get-istio-multicluster

$ mkdir /tmp/istio-input/
```

<details>
<summary>Details</summary>

_To be updated_

</details>

---

### 1. Root CA prep

```bash
$ {
    openssl genrsa -des3 -out /tmp/istio-input/root-ca-passphrase.key 4096
    openssl req \
        -new \
        -x509 \
        -days 365 \
        -config configs/openssl.config \
        -key /tmp/istio-input/root-ca-passphrase.key \
        -out /tmp/istio-input/root-cert.pem \
        -subj "/C=GB/ST=London/L=London/O=Some Dev Inc./OU=Some Dev Root CA/CN=some.dev"
    openssl rsa \
        -in /tmp/istio-input/root-ca-passphrase.key \
        -out /tmp/istio-input/root-key.pem
}
```

<details>
<summary>Details</summary>

_To be updated_

</details>

---

<!--
Likely not needed
### 3. Intermediate CA prep

```bash
$ {
    openssl genrsa -des3 -out /tmp/istio-input/intermediate-ca-passphrase.key 4096
    openssl req \
        -new \
        -sha256 \
        -config configs/openssl.config \
        -key /tmp/istio-input/intermediate-ca-passphrase.key \
        -out /tmp/istio-input/intermediate-ca-passphrase.csr \
        -subj "/C=GB/ST=London/L=London/O=Some Dev Inc./OU=Some Dev Intermediate CA/CN=some-intermediate.dev"

    openssl ca \
        -config configs/openssl.config \
        -extensions v3_intermediate_ca \
        -days 3650 \
        -notext \
        -md sha256 \
        -cert /tmp/istio-input/root-ca/cert.pem \
        -keyfile /tmp/istio-input/root-ca/key.pem \
        -in /tmp/istio-input/intermediate-ca-passphrase.csr \
        -out /tmp/istio-input/intermediate-ca.crt


    openssl req \
        -new \
        -x509 \
        -days 365 \
        -config configs/openssl.config \
        -key /tmp/istio-input/root-ca-passphrase.key \
        -out /tmp/istio-input/intermediate-ca.crt \
    openssl rsa \
        -in /tmp/istio-input/intermediate-ca-passphrase.key \
        -out /tmp/istio-input/intermediate-ca.key
}
```

<details>
<summary>Details</summary>

Verification

```bash
openssl x509 -noout -text -in /tmp/istio-input/intermediate-ca.crt
```

```bash
openssl verify -CAfile certs/ca.cert.pem \
      intermediate/certs/intermediate.cert.pem
```

_To be updated_

</details>

--- -->

### 2. Client cert prep

Create certs for all clusters

```bash
$ {
    mkdir /tmp/istio-input/armadillo/
    openssl genrsa -out /tmp/istio-input/armadillo/ca-key.pem 2048
    openssl req \
        -new \
        -sha256 \
        -days 365 \
        -config ./configs/openssl.config \
        -key /tmp/istio-input/armadillo/ca-key.pem \
        -out /tmp/istio-input/armadillo/ca.csr \
        -subj "/C=GB/ST=London/L=London/O=Some Dev Inc./OU=Armadillo/CN=some-armadillo.dev"

    mkdir /tmp/istio-input/bison/
    openssl genrsa -out /tmp/istio-input/bison/ca-key.pem 2048
    openssl req \
        -new \
        -sha256 \
        -days 365 \
        -config ./configs/openssl.config \
        -key /tmp/istio-input/bison/ca-key.pem \
        -out /tmp/istio-input/bison/ca.csr \
        -subj "/C=GB/ST=London/L=London/O=Some Dev Inc./OU=Bison/CN=some-bison.dev"
}
```

<details>
<summary>Details</summary>

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
        -CA /tmp/istio-input/root-cert.pem \
        -CAkey /tmp/istio-input/root-key.pem \
        -CAcreateserial \
        -extfile configs/openssl.config \
        -extensions client_cert \
        -in /tmp/istio-input/armadillo/ca.csr \
        -out /tmp/istio-input/armadillo/ca-cert.pem
    openssl x509 \
        -req \
        -sha256 \
        -days 365 \
        -CA /tmp/istio-input/root-cert.pem \
        -CAkey /tmp/istio-input/root-key.pem \
        -CAcreateserial \
        -extfile configs/openssl.config \
        -extensions client_cert \
        -in /tmp/istio-input/bison/ca.csr \
        -out /tmp/istio-input/bison/ca-cert.pem
}
```

<details>
<summary>Details</summary>

- Armadillo will set up Istio IngressGateway with 32021 NodePort
- Bison will set up Istio IngressGateway with 32022 NodePort

</details>

---

### 4. Create Kubernetes Secrets

```bash
$ {
    kubectl create namespace --context kind-armadillo istio-system
    kubectl create secret --context kind-armadillo \
        generic cacerts -n istio-system \
        --from-file=/tmp/istio-input/armadillo/ca-cert.pem \
        --from-file=/tmp/istio-input/armadillo/ca-key.pem \
        --from-file=/tmp/istio-input/root-cert.pem \
        --from-file=/tmp/istio-input/cert-chain.pem

    kubectl create namespace --context kind-bison istio-system
    kubectl create secret --context kind-bison \
        generic cacerts -n istio-system \
        --from-file=/tmp/istio-input/bison/ca-cert.pem \
        --from-file=/tmp/istio-input/bison/ca-key.pem \
        --from-file=/tmp/istio-input/root-cert.pem \
        --from-file=/tmp/istio-input/cert-chain.pem
}
```
