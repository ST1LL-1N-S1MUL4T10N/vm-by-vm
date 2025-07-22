Ubuntu 24.04 – Production‑ready Enterprise Setup
— IP‑Kontext —

* VM1 (DNS): 172.16.110.1 (dns.test.local)
* VM2 (Root & Intermediate CA): 172.16.110.110 (ca.test.local)
* VM3 (OpenLDAP mit LDAPS): 172.16.110.169 (ldap.test.local)
* VM4 (Wiki): 172.16.110.4

---

## VM2 – Enterprise CA (Offline Root + Online Intermediate)

#### 1. System & Benutzer anlegen

```bash
# Root‑CA (offline) und Int‑CA (online) laufen beide auf dieser VM, aber Root‑CA wird danach eingemottet.
sudo apt update
sudo apt install -y openssl

# Service‑Account für CA-Prozesse
sudo adduser --system --no-create-home --group causer
```

#### 2. Verzeichnisstruktur & Dateien

```bash
# Root CA
ROOT=/home/causer/ca-root
sudo mkdir -p $ROOT/{certs,crl,private,newcerts}
sudo chown -R causer:causer $ROOT
sudo chmod 700 $ROOT/private
sudo -u causer touch $ROOT/index.txt
echo 1000 | sudo tee $ROOT/serial

# Intermediate CA
INT=/home/causer/ca-int
sudo mkdir -p $INT/{certs,crl,private,newcerts}
sudo chown -R causer:causer $INT
sudo chmod 700 $INT/private
sudo -u causer touch $INT/index.txt
echo 1000 | sudo tee $INT/serial
```

#### 3. OpenSSL‑Konfiguration (Root & Int)

```bash
# Root‑CA openssl.cnf
cat > $ROOT/openssl.cnf <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $ROOT
certs             = \$dir/certs
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
private_key       = \$dir/private/ca.key.pem
certificate       = \$dir/certs/ca.cert.pem
default_md        = sha256
default_days      = 3650
policy            = policy_strict

[ policy_strict ]
countryName        = match
stateOrProvinceName= optional
organizationName   = match
commonName         = supplied

[ req ]
default_bits       = 4096
distinguished_name = req_dn
x509_extensions    = v3_ca

[ req_dn ]
countryName_default        = DE
stateOrProvinceName_default= Hessen
localityName_default       = Frankfurt
0.organizationName_default = TestPlanck
organizationalUnitName_default = IT
commonName_default         = TestPlanck Root CA

[ v3_ca ]
basicConstraints       = critical,CA:true,pathlen:1
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer

[ crl_ext ]
authorityKeyIdentifier = keyid:always
EOF

# Intermediate‑CA openssl.cnf (analog, aber default_days=1825, commonName "TestPlanck Intermediate CA")
sed -e "s|dir               = $ROOT|dir               = $INT|" \
    -e "s|commonName_default         = TestPlanck Root CA|commonName_default         = TestPlanck Intermediate CA|" \
    -e "s|default_days      = 3650|default_days      = 1825|" \
  $ROOT/openssl.cnf > $INT/openssl.cnf
```

#### 4. Schlüssel & Zertifikate erzeugen

```bash
# Root Key & Cert (offline)
sudo -u causer openssl genrsa -aes256 -out $ROOT/private/ca.key.pem 4096
sudo chmod 400 $ROOT/private/ca.key.pem
sudo -u causer openssl req -config $ROOT/openssl.cnf \
  -key $ROOT/private/ca.key.pem \
  -new -x509 -days 3650 -sha256 -extensions v3_ca \
  -out $ROOT/certs/ca.cert.pem

# Intermediate Key & CSR
sudo -u causer openssl genrsa -out $INT/private/int.key.pem 4096
sudo chmod 400 $INT/private/int.key.pem
sudo -u causer openssl req -config $INT/openssl.cnf \
  -key $INT/private/int.key.pem \
  -new -sha256 \
  -out $INT/int.csr.pem

# Sign Intermediate with Root (offline step; Root‑CA sicher verwahren)
sudo -u causer openssl ca -config $ROOT/openssl.cnf \
  -extensions v3_ca -days 1825 -notext -md sha256 \
  -in $INT/int.csr.pem \
  -out $INT/certs/int.cert.pem

# Chainfile erstellen
cat $INT/certs/int.cert.pem $ROOT/certs/ca.cert.pem | sudo tee $INT/certs/ca-chain.pem
```

#### 5. CRL und Automatisierung

```bash
# CRL-Nummer persistent anlegen
echo 1000 | sudo tee $INT/crlnumber

# CRL generieren
sudo -u causer openssl ca -config $INT/openssl.cnf -gencrl -out $INT/crl/int.crl.pem

# Beispiel Script für CRL-Erneuerung (crl_renew.sh)
cat > /usr/local/bin/crl_renew.sh <<'EOS'
#!/usr/bin/env bash
INT=/home/causer/ca-int
cd $INT
openssl ca -config openssl.cnf -gencrl -out crl/int.crl.pem
EOS
sudo chmod +x /usr/local/bin/crl_renew.sh
# Cronjob: CRL täglich erneuern
echo "0 2 * * * root /usr/local/bin/crl_renew.sh" | sudo tee /etc/cron.d/renew_crl
```

> **Hinweis:** Enterprise‑Setups nutzen oft eine Offline‑Root und eine Online‑Intermediate CA zur Minimierung des Root‑Kompromissrisikos ([Reddit][1]). Regelmäßige CRL‑Erneuerung ist Best Practice ([Server Fault][2]).

---

## VM3 – OpenLDAP mit LDAPS & Härtung

#### 1. Pakete & Debconf‑Preseed

```bash
sudo apt update
sudo debconf-set-selections <<EOF
slapd slapd/no_configuration boolean false
slapd slapd/domain string test.local
slapd shared/organization string TestPlanck
slapd slapd/password1 password testldap123
slapd slapd/password2 password testldap123
EOF
DEBIAN_FRONTEND=noninteractive sudo apt install -y slapd ldap-utils
```

#### 2. Hosts & TLS‑Verzeichnisse

```bash
sudo hostnamectl set-hostname ldap.test.local
echo -e "172.16.110.169\tldap.test.local\tldap" | sudo tee -a /etc/hosts

sudo mkdir -p /etc/ldap/tls/{private,certs}
sudo chown -R openldap:openldap /etc/ldap/tls
sudo chmod 700 /etc/ldap/tls/private
```

#### 3. Server‑Key, CSR & Signierung

```bash
# Key & CSR
sudo openssl genrsa -out /etc/ldap/tls/private/ldap.key.pem 4096
sudo chmod 400 /etc/ldap/tls/private/ldap.key.pem
sudo openssl req -new -key /etc/ldap/tls/private/ldap.key.pem \
  -subj "/C=DE/ST=Hessen/L=Frankfurt/O=TestPlanck/OU=IT/CN=ldap.test.local" \
  -out /etc/ldap/tls/ldap.csr.pem

# Signiere auf CA‑VM (Intermediate)
scp /etc/ldap/tls/ldap.csr.pem ca@172.16.110.110:/home/causer/ca-int/
ssh ca@172.16.110.110 " \
  openssl ca -config /home/causer/ca-int/openssl.cnf \
    -extensions v3_ca -days 825 -notext -md sha256 \
    -in /home/causer/ca-int/ldap.csr.pem \
    -out /home/causer/ca-int/ldap.cert.pem \
  && chmod 444 /home/causer/ca-int/ldap.cert.pem"
```

#### 4. Zertifikat‑Kette & Härtung

```bash
# Zertifikate zurückholen
scp ca@172.16.110.110:/home/causer/ca-int/ldap.cert.pem /tmp/
scp ca@172.16.110.110:/home/causer/ca-int/ca-chain.pem /tmp/

sudo mv /tmp/{ca-chain.pem,ldap.cert.pem} /etc/ldap/tls/certs/
sudo chown openldap:openldap /etc/ldap/tls/certs/*.pem
sudo chmod 444 /etc/ldap/tls/certs/*.pem

# LDIF für TLS + Härtung (nur TLS1.2+, sichere Cipher)
cat <<EOF | sudo tee /etc/ldap/tls.ldif
dn: cn=config
changetype: modify
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ldap/tls/certs/ca-chain.pem
-
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/tls/certs/ldap.cert.pem
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/tls/private/ldap.key.pem
-
add: olcTLSProtocolMin
olcTLSProtocolMin: 3.3
-
add: olcTLSCipherSuite
olcTLSCipherSuite: HIGH:!aNULL:!MD5:!RC4
EOF

sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /etc/ldap/tls.ldif
sudo systemctl restart slapd
```

> **Hinweis:** Mindestens TLS 1.2 erzwingen und Cipher‑Suite härtung verhindern Man‑in‑the‑Middle ([Ubuntu Dokumentation][3]).

---

## VM4 – Wiki (LDAP‑Integration)

#### 1. Zertifikat‑Import ins Java‑Truststore

```bash
# CA‑Chain und LDAP‑Server‑Cert auf VM4 bereitstellen
scp ldap@172.16.110.169:/etc/ldap/tls/certs/ca-chain.pem ~/
scp ldap@172.16.110.169:/etc/ldap/tls/certs/ldap.cert.pem ~/

# Java‑Keystore ermitteln & importieren
JAVA_CACERTS=$(readlink -f $(dirname $(dirname $(readlink -f $(which java))))/lib/security/cacerts)
sudo keytool -importcert -noprompt -trustcacerts \
    -alias testplanck-ca \
    -file ~/ca-chain.pem \
    -keystore $JAVA_CACERTS \
    -storepass changeit

sudo keytool -importcert -noprompt -trustcacerts \
    -alias ldap-server \
    -file ~/ldap.cert.pem \
    -keystore $JAVA_CACERTS \
    -storepass changeit
```

#### 2. XWiki LDAP‑Konfiguration

```bash
sudo sed -i 's|^xwiki.authentication.ldap.server=.*|xwiki.authentication.ldap.server=ldaps://ldap.test.local:636|' /etc/xwiki/xwiki.cfg
sudo sed -i 's|^xwiki.authentication.ldap.bindUser=.*|xwiki.authentication.ldap.bindUser=cn=admin,dc=test,dc=local|' /etc/xwiki/xwiki.cfg
sudo sed -i 's|^xwiki.authentication.ldap.bindPassword=.*|xwiki.authentication.ldap.bindPassword=testldap123|' /etc/xwiki/xwiki.cfg
sudo sed -i 's|^xwiki.authentication.ldap.base_DN=.*|xwiki.authentication.ldap.base_DN=dc=test,dc=local|' /etc/xwiki/xwiki.cfg
```

#### 3. Neustart

```bash
sudo systemctl restart xwiki
```

> **Hinweis:** Dies entspricht Enterprise‑Best Practices mit Offline‑Root, Online‑Intermediate, automatisierter CRL‑Erneuerung, TLS‑Härtung und sicherer Java‑Keystore‑Integration.

[1]: https://www.reddit.com/r/sysadmin/comments/qbc9cp/enterprise_root_ca_for_internal_ssl_certificates/?utm_source=chatgpt.com "Enterprise Root CA for internal SSL Certificates, best practices?"
[2]: https://serverfault.com/questions/306345/certification-authority-root-certificate-expiry-and-renewal?utm_source=chatgpt.com "Certification authority root certificate expiry and renewal - Server Fault"
[3]: https://documentation.ubuntu.com/server/how-to/security/install-a-root-ca-certificate-in-the-trust-store/?utm_source=chatgpt.com "Install a root CA certificate in the trust store - Ubuntu documentation"
