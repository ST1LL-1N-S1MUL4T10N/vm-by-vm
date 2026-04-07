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

---

#### ✅ Option 1: **Per-IP Log Separation**

This logs messages to files based on the **client's IP address**.

##### 📁 File: `/etc/rsyslog.d/20-client-ip-routing.conf`

```rsyslog
# Template for logging by IP address
template(name="PerIPLog" type="string" string="/var/log/remote/%FROMHOST-IP%/syslog.log")

# Route all messages to the per-IP log
*.* ?PerIPLog
```

> ✅ Result: `/var/log/remote/192.168.0.248/syslog.log`, etc.

---

#### ✅ Option 2: **Per-Hostname Log Separation**

This logs messages to files based on the **client's hostname** (as reported in the syslog message).

##### 📁 File: `/etc/rsyslog.d/20-client-host-routing.conf`

```rsyslog
# Template for logging by hostname
template(name="PerHostLog" type="string" string="/var/log/remote/%HOSTNAME%/syslog.log")

# Route all messages to the per-hostname log
*.* ?PerHostLog
```

> ✅ Result: `/var/log/remote/logclient1/syslog.log`, etc.

---


#### 🔄 Apply Changes and restart Rsyslog Service (Server)

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

#### 🔄 Restart Rsyslog Service (Client)

```bash
sudo systemctl restart rsyslog
```

> ⚠️ Might need to use `rsyslog` instead of `syslog`.

---

### ✅ Verification

#### On the **Server** (to watch logs):


###### 🔎 If using **per-IP** logs

```bash
tail -f /var/log/remote/<client-ip>/syslog.log
```

**Example:**

```bash
tail -f /var/log/remote/192.168.0.248/syslog.log
```

---

##### 🔎 If using **per-hostname** logs

```bash
tail -f /var/log/remote/<client-hostname>/syslog.log
```

**Example:**

```bash
tail -f /var/log/remote/logclient1/syslog.log
```

---

#### 🔁 Live View for All Clients (optional)

To see everything from all clients in one stream (not separated):

```bash
tail -f /var/log/syslog
```

or

```bash
tail -f /var/log/remote/*/syslog.log
```

(Use with caution — this can get noisy if many clients are logging.)

---

#### On the **Client** (to generate test log):

```bash
logger "TESTLOG"
```

---
