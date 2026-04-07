# 🧰 Certificate Installation

### Preparation:

#### Convert:

<img width="1462" height="90" alt="convertca" src="https://github.com/user-attachments/assets/17f3e545-3ef0-4e57-a93b-4764f7f92ce6" />



After running the containers with:

```bash
cd /opt/xwiki
sudo docker compose up -d
```

You need to add your CA cert into the running container:

### Step 1: Enter the container

```bash
sudo docker exec -it xwiki-mysql-tomcat-web bash
```

### Step 2: Trust the system CA

```bash
update-ca-certificates
```

### Step 3: Trust the CA in JVM

```bash
keytool -importcert -trustcacerts -alias ldap-ca \
  -file /usr/local/share/ca-certificates/ldap-ca.crt \
  -keystore $JAVA_HOME/lib/security/cacerts \
  -storepass changeit -noprompt
```


<img width="1547" height="495" alt="addca" src="https://github.com/user-attachments/assets/8e6ab1d3-8b9a-44f1-9cee-12ed50d98054" />


### Step 4: Restart the container

```bash
exit
sudo docker restart xwiki-mysql-tomcat-web
```

---

## 🚀 Run and Test







