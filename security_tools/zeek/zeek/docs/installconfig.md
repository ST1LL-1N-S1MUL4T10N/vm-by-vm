
---

# Zeek Installation & Setup on Ubuntu 24.04 — Step by Step

### 1. Add Zeek Repository

```bash
echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_24.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
```

### 2. Add GPG Key for the Repo

```bash
curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_24.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
```

### 3. Update Package Lists

```bash
sudo apt update
```

### 4. Install Zeek (LTS Version)

```bash
sudo apt install zeek
```

### 5. Add Zeek to PATH

```bash
echo "export PATH=$PATH:/opt/zeek/bin" >> ~/.bashrc
source ~/.bashrc
```

### 6. Verify Zeek Installation

```bash
zeek --version
zeek --help
```

---

### 7. Give Zeek Binary Required Capabilities

```bash
sudo setcap cap_net_raw,cap_net_admin=eip /opt/zeek/bin/zeek
```

---

### 8. Configure Network for Zeek

Check your server IP and interfaces:

```bash
ip a
```

---

### 9. Edit Network Subnets for Zeek

```bash
sudo nano /opt/zeek/etc/networks.cfg
```

Add subnet:

```
192.168.0.0/24 Local Network
```

Save and exit.

---

### 10. Configure Zeek Cluster Nodes

```bash
sudo nano /opt/zeek/etc/node.cfg
```

Comment out the standalone section:

```ini
#[zeek]
#type=standalone
#host=localhost
#interface=eth0
```

Add the cluster mode config using IP `192.168.0.33` and interface `eth0`:

```ini
# logger
[zeek-logger]
type=logger
host=192.168.0.33

# manager
[zeek-manager]
type=manager
host=192.168.0.33

# proxy
[zeek-proxy]
type=proxy
host=192.168.0.33

# worker
[zeek-worker]
type=worker
host=192.168.0.33
interface=eth0

# worker localhost
[zeek-worker-lo]
type=worker
host=localhost
interface=lo
```

Save and exit.

---

### 11. Check Zeek Scripts Syntax

```bash
sudo /opt/zeek/bin/zeekctl check
```

Expected output:

scripts are ok


---

### 12. Deploy Zeek

```bash
sudo /opt/zeek/bin/zeekctl deploy
```

---

### 13. Check Zeek Components Status

```bash
zeekctl status
```

---

### 14. Enable JSON Logging

```bash
sudo nano /opt/zeek/share/zeek/site/local.zeek
```

Uncomment or add:

```zeek
@load policy/tuning/json-logs
```

Save and exit.

---

### 15. Redeploy Zeek for Changes

```bash
sudo zeekctl deploy
```

---

### 16. Verify JSON Logs

```bash
cat /opt/zeek/logs/current/dns.log
```
