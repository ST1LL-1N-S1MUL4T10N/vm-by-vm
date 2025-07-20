### 📝 Rsyslog Setup Log

#### 📦 Installation (Server)

```bash
sudo apt install rsyslog
```

#### ⚙️ Configuration File Edit (Server)

```bash
sudo nano /etc/rsyslog.conf
```

#### 🔧 Enable UDP and TCP Reception (in `rsyslog.conf`)

```rsyslog
module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp")
input(type="imtcp" port="514")
```

#### 🔄 Restart Rsyslog Service (Server)

```bash
sudo systemctl restart rsyslog
```

---

#### 📦 Installation (Client)

```bash
sudo apt install rsyslog -y
```

#### ⚙️ Configuration File Edit (Client)

```bash
sudo nano /etc/rsyslog.conf
```

#### 📨 Forward All Logs to Remote Rsyslog Server (in `rsyslog.conf`)

```rsyslog
*.* @192.168.3.234:514
```

> `@` for UDP, `@@` for TCP.

#### 🔄 Restart Syslog Service (Client)

```bash
sudo systemctl restart syslog
```

> ⚠️ Might need to use `rsyslog` instead of `syslog`.

---

### ✅ Verification

#### On the **Server** (to watch logs):

```bash
tail -f /var/log/messages
```

#### On the **Client** (to generate test log):

```bash
logger "TESTLOG"
```

---
