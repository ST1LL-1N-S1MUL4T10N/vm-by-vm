## Ubuntu 24.04

### VM1 – DNS (bereits eingerichtet)

> IP: `172.16.110.1`
> Hostname: `dns.test.local`
> *Nur als Kontext; keine weiteren Schritte hier.*

---

### VM2 – Certificate Authority (CA)

#### 1. System vorbereiten

```bash
sudo apt update
sudo apt install -y openssl
```

#### 2. Hostname & `/etc/hosts`

```bash
sudo hostnamectl set-hostname ca.test.local
echo -e "172.16.110.110\tca.test.local\tca" | sudo tee -a /etc/hosts
```

#### 3. CA-Verzeichnisstruktur anlegen

```bash
export CA_HOME=/home/ca/ca
sudo -u ca mkdir -p $CA_HOME/{certs,crl,newcerts,private}
sudo chmod 700 $CA_HOME/private
sudo -u ca touch $CA_HOME/index.txt
echo 1000 | sudo tee $CA_HOME/serial
```

#### 4. OpenSSL‑Konfiguration erstellen

```bash
cat > $CA_HOME/openssl.cnf <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $CA_HOME
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

private_key       = \$dir/private/ca.key.pem
certificate       = \$dir/certs/ca.cert.pem

crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

default_md        = sha256
policy            = policy_strict

[ policy_strict ]
countryName         = match
stateOrProvinceName = optional
organizationName    = match
commonName          = supplied

[ req ]
default_bits        = 4096
distinguished_name  = req_dn
x509_extensions     = v3_ca

[ req_dn ]
countryName               = Country Name (2 letter code)
stateOrProvinceName       = State or Province Name
localityName              = Locality Name
0.organizationName        = Organization Name
organizationalUnitName    = Organizational Unit Name
commonName                = Common Name

countryName_default        = DE
stateOrProvinceName_default= Hessen
localityName_default       = Frankfurt
0.organizationName_default = TestPlanck
organizationalUnitName_default = IT
commonName_default         = TestPlanck Root CA

[ v3_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical,CA:true
keyUsage               = critical,digitalSignature,cRLSign,keyCertSign

[ crl_ext ]
authorityKeyIdentifier = keyid:always
EOF
```

#### 5. Root‑Key & Zertifikat erzeugen

```bash
sudo -u ca openssl genrsa -aes256 -out $CA_HOME/private/ca.key.pem 4096
sudo chmod 400 $CA_HOME/private/ca.key.pem

sudo -u ca openssl req -config $CA_HOME/openssl.cnf \
    -key $CA_HOME/private/ca.key.pem \
    -new -x509 -days 3650 -sha256 -extensions v3_ca \
    -out $CA_HOME/certs/ca.cert.pem
sudo chmod 444 $CA_HOME/certs/ca.cert.pem
```

#### 6. CA‑Zertifikat prüfen

```bash
sudo -u ca openssl x509 -noout -text -in $CA_HOME/certs/ca.cert.pem
```

---

### VM3 – OpenLDAP mit LDAPS

#### 1. Pakete installieren

```bash
sudo apt update
DEBIAN_FRONTEND=noninteractive sudo apt install -y slapd ldap-utils
```

#### 2. Hostname & `/etc/hosts`

```bash
sudo hostnamectl set-hostname ldap.test.local
echo -e "172.16.110.169\tldap.test.local\tldap" | sudo tee -a /etc/hosts
```

#### 3. TLS‑Verzeichnisstruktur

```bash
sudo mkdir -p /etc/ldap/tls/{private,certs}
sudo chown -R openldap:openldap /etc/ldap/tls
sudo chmod 700 /etc/ldap/tls/private
```

#### 4. LDAP‑Key & CSR erstellen

```bash
sudo openssl genrsa -out /etc/ldap/tls/private/ldap.key.pem 2048
sudo chmod 600 /etc/ldap/tls/private/ldap.key.pem

sudo openssl req -new -key /etc/ldap/tls/private/ldap.key.pem \
    -subj "/C=DE/ST=Hessen/L=Frankfurt/O=TestPlanck/OU=IT/CN=ldap.test.local" \
    -out /etc/ldap/tls/ldap.csr.pem
```

#### 5. CSR zur CA übertragen & signieren

```bash
scp /etc/ldap/tls/ldap.csr.pem ca@172.16.110.110:/home/ca/ca/
ssh ca@172.16.110.110 " \
    openssl ca -config /home/ca/ca/openssl.cnf \
      -extensions server_cert -days 825 -notext -md sha256 \
      -in /home/ca/ca/ldap.csr.pem \
      -out /home/ca/ca/ldap.cert.pem && \
    chmod 444 /home/ca/ca/ldap.cert.pem \
"
```

#### 6. Zertifikate zurückholen

```bash
scp ca@172.16.110.110:/home/ca/ca/ldap.cert.pem /tmp/
scp ca@172.16.110.110:/home/ca/ca/certs/ca.cert.pem /tmp/

sudo mv /tmp/{ldap.cert.pem,ca.cert.pem} /etc/ldap/tls/certs/
sudo chown openldap:openldap /etc/ldap/tls/certs/*.pem
sudo chmod 444 /etc/ldap/tls/certs/*.pem
```

#### 7. LDAPS aktivieren

```bash
cat <<EOF | sudo tee /etc/ldap/tls.ldif
dn: cn=config
changetype: modify
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ldap/tls/certs/ca.cert.pem
-
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/tls/certs/ldap.cert.pem
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/tls/private/ldap.key.pem
EOF

sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /etc/ldap/tls.ldif
sudo systemctl restart slapd
```

#### 8. LDAPS testen

```bash
ldapsearch -H ldaps://ldap.test.local:636 -x -b dc=test,dc=local \
    -D "cn=admin,dc=test,dc=local" -w testldap123
```

#### 9. Firewall (optional)

```bash
sudo ufw allow 636/tcp
```

---

### VM4 – Wiki (Integration)

#### 1. Zertifikate kopieren

```bash
# Auf VM3:
scp /etc/ldap/tls/certs/ca.cert.pem user@172.16.110.4:/home/user/
scp /etc/ldap/tls/certs/ldap.cert.pem user@172.16.110.4:/home/user/
```

#### 2. CA & LDAP‑Zertifikat importieren (Java Truststore)

```bash
sudo keytool -import -noprompt -trustcacerts \
    -alias testplanck-ca \
    -file /home/user/ca.cert.pem \
    -keystore /etc/ssl/certs/java/cacerts \
    -storepass changeit

sudo keytool -import -noprompt -trustcacerts \
    -alias ldap-test \
    -file /home/user/ldap.cert.pem \
    -keystore /etc/ssl/certs/java/cacerts \
    -storepass changeit
```

#### 3. XWiki‑Konfiguration anpassen

```bash
sudo sed -i 's|^xwiki.authentication.ldap.server=.*|xwiki.authentication.ldap.server=ldaps://ldap.test.local:636|' /etc/xwiki/xwiki.cfg
sudo sed -i 's|^xwiki.authentication.ldap.bindUser=.*|xwiki.authentication.ldap.bindUser=cn=admin,dc=test,dc=local|' /etc/xwiki/xwiki.cfg
sudo sed -i 's|^xwiki.authentication.ldap.bindPassword=.*|xwiki.authentication.ldap.bindPassword=testldap123|' /etc/xwiki/xwiki.cfg
sudo sed -i 's|^xwiki.authentication.ldap.base_DN=.*|xwiki.authentication.ldap.base_DN=dc=test,dc=local|' /etc/xwiki/xwiki.cfg
```

#### 4. XWiki‑Service neu starten

```bash
sudo systemctl restart xwiki
```
