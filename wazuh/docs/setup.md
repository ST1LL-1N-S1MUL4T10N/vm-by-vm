
---

### 1. **Setup Wazuh Single-Node Docker Deployment**

* Cloned Wazuh Docker repo (v4.12.0):

  ```bash
  git clone https://github.com/wazuh/wazuh-docker.git -b v4.12.0
  cd wazuh-docker/single-node
  ```
* Generated or provided SSL certificates (optional).
 * (Generated):
```bash
  docker-compose -f generate-indexer-certs.yml run --rm generator
  ```

* Start Wazuh stack:

  ```bash
  docker-compose up -d
  ```

---

### 2. **Added & Registered Wazuh Agent on Another Node (Suricata Node)**

* Installed Wazuh agent on Suricata node.
* Registered the agent with the Wazuh manager.
* Confirmed the agent status as **registered** on Wazuh server.

---

### 3. **Configured Wazuh Agent to Collect Suricata Logs**


* On the node running Wazuh Agent, find the config:

```
/var/ossec/etc/ossec.conf
```


* Edit `ossec.conf` on Suricata node to add Suricata EVE JSON log:

  ```xml
  <localfile>
    <log_format>json</log_format>
    <location>/var/log/suricata/eve.json</location>
  </localfile>
  ```
* Ensured the `eve.json` log file was accessible by the `wazuh` user:

  ```bash
  sudo chgrp wazuh /var/log/suricata/eve.json
  sudo chmod 640 /var/log/suricata/eve.json
  ```
* Restarted Wazuh agent on Suricata node:

  ```bash
  sudo systemctl restart wazuh-agent
  ```

---

### 4. **Verified Logs Are Being Collected**

* Checked Wazuh logs on Suricata node:

  ```bash
  tail -f /var/ossec/logs/ossec.log
  ```
* Confirmed Suricata logs appeared in Wazuh dashboard under `rule.groups:suricata`.

---

### 5. **Filtered Suricata Alerts in Wazuh Dashboard**

* Used Wazuh Dashboard search filter for specific alert signature:

  ```
  rule.groups:suricata AND data.alert.signature:""
  ```

---
