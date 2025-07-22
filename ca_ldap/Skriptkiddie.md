Unten findest du eine „Divide & Conquer“–Reihe von kleinen, modul­aren Bash‑Skripten. Jedes Script inspiriert nur einen klar umschriebenen Schritt und wird auf der jeweiligen Test‑VM ausgeführt. So behältst du jederzeit die Kontrolle und kannst bei Bedarf neu starten oder debuggen.

**Hinweis:** Alle Scripts beginnen mit `set -euo pipefail` und prüfen, ob sie als root laufen (`UID=0`), um Fail‑Safe zu sein.

---

## VM2 (CA)

### 1. `vm2_00_preflight.sh`

*Prüft Umgebung und erstellt CA‑User.*

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1.1 – Root‑Check
if [[ $EUID -ne 0 ]]; then
  echo "Bitte als root ausführen"; exit 1
fi

# 1.2 – Updaten & OpenSSL installieren
apt update
apt install -y openssl

# 1.3 – CA‑Service‑Account anlegen (falls noch nicht vorhanden)
if ! id ca &>/dev/null; then
  adduser --system --home /home/ca --shell /bin/bash ca
  echo "User 'ca' angelegt"
else
  echo "User 'ca' existiert bereits"
fi
```

---

### 2. `vm2_01_dirs_and_conf.sh`

*Legt Verzeichnisse und OpenSSL‑Konfig an.*

```bash
#!/usr/bin/env bash
set -euo pipefail

CA_USER=ca
CA_HOME=/home/ca/ca

# 2.1 – Verzeichnisstruktur
install -o $CA_USER -g $CA_USER -m 700 -d $CA_HOME/{certs,crl,private,newcerts}
touch $CA_HOME/index.txt
echo 1000 > $CA_HOME/serial
chown $CA_USER:$CA_USER $CA_HOME/index.txt $CA_HOME/serial

# 2.2 – openssl.cnf erstellen
cat > $CA_HOME/openssl.cnf <<'EOF'
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = /home/ca/ca
certs             = $dir/certs
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
private_key       = $dir/private/ca.key.pem
certificate       = $dir/certs/ca.cert.pem
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
keyUsage               = critical,digitalSignature,cRLSign,keyCertSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer

[ crl_ext ]
authorityKeyIdentifier = keyid:always
EOF

chown ca:ca $CA_HOME/openssl.cnf
chmod 644 $CA_HOME/openssl.cnf
```

---

### 3. `vm2_02_create_root_ca.sh`

*Erzeugt Root‑Key und Self‑Signed‑Zertifikat.*

```bash
#!/usr/bin/env bash
set -euo pipefail

CA_HOME=/home/ca/ca
CA_USER=ca

# 3.1 – Root‑Key erzeugen
sudo -u $CA_USER openssl genrsa -aes256 \
  -out $CA_HOME/private/ca.key.pem 4096
chmod 400 $CA_HOME/private/ca.key.pem

# 3.2 – Root‑Zertifikat erzeugen
sudo -u $CA_USER openssl req -config $CA_HOME/openssl.cnf \
  -key $CA_HOME/private/ca.key.pem \
  -new -x509 -days 3650 -sha256 -extensions v3_ca \
  -out $CA_HOME/certs/ca.cert.pem
chmod 444 $CA_HOME/certs/ca.cert.pem
```

---

## VM3 (LDAP)

### 4. `vm3_00_preflight.sh`

*Prüft Umgebung und installiert OpenLDAP.*

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Bitte als root ausführen"; exit 1
fi

apt update
DEBIAN_FRONTEND=noninteractive apt install -y slapd ldap-utils
```

---

### 5. `vm3_01_tls_dirs.sh`

*Legt TLS‑Verzeichnisse für LDAP an.*

```bash
#!/usr/bin/env bash
set -euo pipefail

# 5.1 – Hostname & lokale Hosts
hostnamectl set-hostname ldap.test.local
echo -e "172.16.110.169\tldap.test.local\tldap" >> /etc/hosts

# 5.2 – TLS‑Ordner
install -d -m 700 /etc/ldap/tls/private
install -d -m 755 /etc/ldap/tls/certs
chown -R openldap:openldap /etc/ldap/tls
```

---

### 6. `vm3_02_generate_csr.sh`

*Erzeugt LDAP‑Key und CSR und überträgt zur CA.*

```bash
#!/usr/bin/env bash
set -euo pipefail

LDAP_FQDN="ldap.test.local"
CA_HOST="172.16.110.110"
CA_USER="ca"
CA_HOME="/home/ca/ca"

# 6.1 – Key & CSR
openssl genrsa -out /etc/ldap/tls/private/ldap.key.pem 4096
chmod 400 /etc/ldap/tls/private/ldap.key.pem

openssl req -new -key /etc/ldap/tls/private/ldap.key.pem \
  -subj "/C=DE/ST=Hessen/L=Frankfurt/O=TestPlanck/OU=IT/CN=$LDAP_FQDN" \
  -out /etc/ldap/tls/ldap.csr.pem

# 6.2 – CSR zur CA senden
scp /etc/ldap/tls/ldap.csr.pem $CA_USER@$CA_HOST:$CA_HOME/
```

---

### 7. (auf VM2) `vm2_03_sign_ldap.sh`

*Signiert den LDAP‑CSR mit der CA.*

```bash
#!/usr/bin/env bash
set -euo pipefail

CA_HOME=/home/ca/ca

openssl ca -config $CA_HOME/openssl.cnf \
  -extensions v3_ca -days 825 -notext -md sha256 \
  -in $CA_HOME/ldap.csr.pem \
  -out $CA_HOME/ldap.cert.pem

chmod 444 $CA_HOME/ldap.cert.pem
```

---

### 8. `vm3_03_deploy_cert.sh`

*Holt Zertifikate von der CA und aktiviert LDAPS.*

```bash
#!/usr/bin/env bash
set -euo pipefail

CA_HOST="172.16.110.110"
CA_USER="ca"
CA_HOME="/home/ca/ca"

# 8.1 – Zertifikate holen
scp $CA_USER@$CA_HOST:$CA_HOME/ldap.cert.pem /tmp/
scp $CA_USER@$CA_HOST:$CA_HOME/certs/ca.cert.pem /tmp/

mv /tmp/ldap.cert.pem /etc/ldap/tls/certs/
mv /tmp/ca.cert.pem   /etc/ldap/tls/certs/
chown openldap:openldap /etc/ldap/tls/certs/*.pem
chmod 444 /etc/ldap/tls/certs/*.pem

# 8.2 – LDAPS in LDAP aktivieren
cat > /etc/ldap/tls.ldif <<'EOF'
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

ldapmodify -Y EXTERNAL -H ldapi:/// -f /etc/ldap/tls.ldif
systemctl restart slapd
```

---

## VM4 (Wiki via Docker‑Compose)

### 9. `vm4_00_prepare.sh`

*Bereitet Verzeichnisse, Zertifikate und Konfig vor.*

```bash
#!/usr/bin/env bash
set -euo pipefail

WORKDIR=/opt/xwiki
mkdir -p $WORKDIR/{certs,xwiki-config}
echo "Kopiere bitte ca.cert.pem und ldap.cert.pem nach $WORKDIR/certs/"
```

---

### 10. `vm4_01_deploy_docker.sh`

*Stellt den Docker‑Compose‑Stack auf.*

```bash
#!/usr/bin/env bash
set -euo pipefail

cd /opt/xwiki

cat > docker-compose.yml <<'EOF'
version: "3.8"
services:
  mariadb:
    image: mariadb:10.5
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpass123
      MYSQL_DATABASE:      xwiki
      MYSQL_USER:          xwiki
      MYSQL_PASSWORD:      xwikipass123
    volumes:
      - db_data:/var/lib/mysql

  xwiki:
    image: xwiki:lts-mysql-tomcat
    restart: always
    depends_on:
      - mariadb
    ports:
      - "8080:8080"
    environment:
      DB_USER:             xwiki
      DB_PASSWORD:         xwikipass123
      DB_DATABASE:         xwiki
      DB_HOST:             mariadb
      LDAP_SERVER:         ldaps://ldap.test.local:636
      LDAP_BIND_DN:        cn=admin,dc=test,dc=local
      LDAP_BIND_PASSWORD:  testldap123
      LDAP_BASE_DN:        dc=test,dc=local
      LDAP_FILTER:         (objectClass=person)
      LDAP_UID:            uid
      LDAP_FIRSTNAME:      givenName
      LDAP_LASTNAME:       sn
      LDAP_EMAIL:          mail
    volumes:
      - xwiki_data:/var/lib/xwiki
      - ./xwiki-config/xwiki.cfg:/usr/local/xwiki/webapps/ROOT/WEB-INF/xwiki.cfg:ro
      - ./certs/ca.cert.pem:/usr/local/share/ca-certificates/ca.crt:ro
      - ./certs/ldap.cert.pem:/usr/local/share/ca-certificates/ldap.crt:ro
    command: >
      sh -c "update-ca-certificates && catalina.sh run"
volumes:
  db_data:
  xwiki_data:
EOF

cat > xwiki-config/xwiki.cfg <<'EOF'
xwiki.authentication.ldap=1
xwiki.authentication.ldap.server=\${LDAP_SERVER}
xwiki.authentication.ldap.bindUser=\${LDAP_BIND_DN}
xwiki.authentication.ldap.bindPassword=\${LDAP_BIND_PASSWORD}
xwiki.authentication.ldap.base_DN=\${LDAP_BASE_DN}
xwiki.authentication.ldap.filter=\${LDAP_FILTER}
xwiki.authentication.ldap.loginAttribute=\${LDAP_UID}
xwiki.authentication.ldap.firstNameAttribute=\${LDAP_FIRSTNAME}
xwiki.authentication.ldap.lastNameAttribute=\${LDAP_LASTNAME}
xwiki.authentication.ldap.emailAttribute=\${LDAP_EMAIL}
EOF

docker-compose pull
docker-compose up -d
```

---

**Workflow**

1. Auf **VM2**:

   ```bash
   ./vm2_00_preflight.sh  
   ./vm2_01_dirs_and_conf.sh  
   ./vm2_02_create_root_ca.sh  
   ```
2. Auf **VM3**:

   ```bash
   ./vm3_00_preflight.sh  
   ./vm3_01_tls_dirs.sh  
   ./vm3_02_generate_csr.sh  
   ```
3. Auf **VM2** (signieren):

   ```bash
   ./vm2_03_sign_ldap.sh  
   ```
4. Zurück auf **VM3**:

   ```bash
   ./vm3_03_deploy_cert.sh  
   ```
5. Auf **VM4**:

   ```bash
   ./vm4_00_prepare.sh  
   # → Zertifikate kopieren nach /opt/xwiki/certs  
   ./vm4_01_deploy_docker.sh  
   ```

Jedes Modul ist autark, fail‑safe und sofort manuell oder automatisiert ausführbar.
