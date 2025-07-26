
# 🧠 Internal PKI Setup for brain.lan (Ubuntu CLI)

## Overview

This guide walks through setting up a **two-tier Certificate Authority (CA)** on Ubuntu using OpenSSL for the internal DNS domain `brain.lan`. It includes:

- Root CA (`ca.brain.lan`) – used only to sign the intermediate
- Intermediate CA (`intermediate.brain.lan`) – used to sign certificates
- Secure directory structure and OpenSSL configuration
- No scripts, no GUI

---

## 📁 Directory Structure

```bash
sudo mkdir -p /etc/ssl/brainlan/{certs,crl,newcerts,private}
sudo chmod 700 /etc/ssl/brainlan/private
sudo touch /etc/ssl/brainlan/index.txt
sudo sh -c 'echo 1000 > /etc/ssl/brainlan/serial'
````

---

## ⚙️ Root CA OpenSSL Config (`/etc/ssl/brainlan/openssl.cnf`)

```ini
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = /etc/ssl/brainlan
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

private_key       = $dir/private/ca.brain.lan.key.pem
certificate       = $dir/certs/ca.brain.lan.cert.pem

crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 3650
preserve          = no
policy            = policy_strict

[ policy_strict ]
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
commonName = Common Name (e.g. server FQDN)

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer

[ crl_ext ]
authorityKeyIdentifier=keyid:always
```

---

## 🔐 Generate Root CA Key & Certificate

```bash
sudo openssl genrsa -aes256 -out /etc/ssl/brainlan/private/ca.brain.lan.key.pem 4096
sudo chmod 400 /etc/ssl/brainlan/private/ca.brain.lan.key.pem

sudo openssl req -config /etc/ssl/brainlan/openssl.cnf \
    -key /etc/ssl/brainlan/private/ca.brain.lan.key.pem \
    -new -x509 -days 3650 -sha256 -extensions v3_ca \
    -out /etc/ssl/brainlan/certs/ca.brain.lan.cert.pem

sudo chmod 444 /etc/ssl/brainlan/certs/ca.brain.lan.cert.pem
```

---

## ✅ Verify Root CA

```bash
openssl x509 -noout -text -in /etc/ssl/brainlan/certs/ca.brain.lan.cert.pem
```

---

## 🧱 Intermediate CA Setup

```bash
sudo mkdir -p /etc/ssl/brainlan/intermediate/{certs,crl,csr,newcerts,private}
sudo chmod 700 /etc/ssl/brainlan/intermediate/private
sudo touch /etc/ssl/brainlan/intermediate/index.txt
sudo sh -c 'echo 1000 > /etc/ssl/brainlan/intermediate/serial'
sudo sh -c 'echo 1000 > /etc/ssl/brainlan/intermediate/crlnumber'
```

---

## ⚙️ Intermediate OpenSSL Config (`/etc/ssl/brainlan/intermediate/openssl.cnf`)

```ini
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = /etc/ssl/brainlan/intermediate
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

private_key       = $dir/private/intermediate.brain.lan.key.pem
certificate       = $dir/certs/intermediate.brain.lan.cert.pem

crlnumber         = $dir/crlnumber
crl               = $dir/crl/intermediate.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 825
preserve          = no
policy            = policy_loose

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 4096
default_md          = sha256
prompt              = no
distinguished_name  = req_distinguished_name
string_mask         = utf8only
x509_extensions     = v3_intermediate_ca

[ req_distinguished_name ]
commonName = intermediate.brain.lan

[ v3_intermediate_ca ]
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer

[ usr_cert ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
authorityKeyIdentifier=keyid:always
```

---

## 🔐 Generate Intermediate Key and CSR

```bash
sudo openssl genrsa -aes256 -out /etc/ssl/brainlan/intermediate/private/intermediate.brain.lan.key.pem 4096
sudo chmod 400 /etc/ssl/brainlan/intermediate/private/intermediate.brain.lan.key.pem

sudo openssl req -config /etc/ssl/brainlan/intermediate/openssl.cnf \
    -new -sha256 \
    -key /etc/ssl/brainlan/intermediate/private/intermediate.brain.lan.key.pem \
    -out /etc/ssl/brainlan/intermediate/csr/intermediate.brain.lan.csr.pem
```

---

## ✍️ Sign Intermediate CSR with Root CA

```bash
sudo openssl ca -config /etc/ssl/brainlan/openssl.cnf \
    -extensions v3_intermediate_ca \
    -days 1825 -notext -md sha256 \
    -in /etc/ssl/brainlan/intermediate/csr/intermediate.brain.lan.csr.pem \
    -out /etc/ssl/brainlan/intermediate/certs/intermediate.brain.lan.cert.pem
```

Follow prompts:

* Confirm signature
* Sign? `y`
* Commit? `y`

Then set permissions:

```bash
sudo chmod 444 /etc/ssl/brainlan/intermediate/certs/intermediate.brain.lan.cert.pem
```

---

## 🔍 Verify Intermediate Certificate

```bash
openssl x509 -noout -text \
  -in /etc/ssl/brainlan/intermediate/certs/intermediate.brain.lan.cert.pem
```

---

## 🔗 Create Certificate Chain File

```bash
cat /etc/ssl/brainlan/intermediate/certs/intermediate.brain.lan.cert.pem \
    /etc/ssl/brainlan/certs/ca.brain.lan.cert.pem | \
    sudo tee /etc/ssl/brainlan/intermediate/certs/ca-chain.brain.lan.pem > /dev/null

sudo chmod 444 /etc/ssl/brainlan/intermediate/certs/ca-chain.brain.lan.pem
```

---

## ✅ Verify Certificate Chain

```bash
openssl verify -CAfile /etc/ssl/brainlan/certs/ca.brain.lan.cert.pem \
  /etc/ssl/brainlan/intermediate/certs/intermediate.brain.lan.cert.pem

```

Expected result:


intermediate.brain.lan.cert.pem: OK



---

## ✅ Result

- ✔️ Secure internal PKI deployed
- ✔️ Root CA (`ca.brain.lan`)
- ✔️ Intermediate CA (`intermediate.brain.lan`)
- ✔️ Proper OpenSSL configs
- ✔️ Certificate chain ready for issuing internal certs

---

## ➡️ Next Steps

- Issue server/client certificates using the Intermediate CA
- Set up CRL/OCSP if needed
- Trust root CA on internal systems (via `/usr/local/share/ca-certificates/`)

---


