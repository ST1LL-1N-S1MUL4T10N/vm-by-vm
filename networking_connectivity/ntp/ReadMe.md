Step-by-step guide to set up a **Chrony NTP server** and configure **clients**.

> ✅ Chrony is the **default** time synchronization service on **Ubuntu 20.04+**. It replaces `ntpd` for most use cases.

---

## ✅ Setup: Chrony NTP Server on Ubuntu

### 1. **Install Chrony**

```bash
sudo apt update
sudo apt install chrony -y
```

This installs `chronyd` and sets it to start on boot.

---

### 2. **Edit Chrony Configuration**

Open the configuration file:

```bash
sudo nano /etc/chrony/chrony.conf
```

#### Modify the following:

* Replace or add external time servers:

  ```conf
  server time.cloudflare.com iburst
  server time.google.com iburst
  ```

* **Allow clients on your local network to sync:**

  ```conf
  allow 192.168.1.0/24
  ```

Replace `192.168.1.0/24` with your actual subnet.

* Optionally: enable hardware clock sync (not needed on virtual machines):

  ```conf
  rtcsync
  ```

---

### 3. **Restart Chrony**

```bash
sudo systemctl restart chrony
sudo systemctl enable chrony
```

---

### 4. **Verify Chrony Server Status**

```bash
chronyc sources -v
```

You should see the server syncing with external sources.

To verify it's listening for clients:

```bash
chronyc tracking
sudo netstat -ulnp | grep chronyd
```

You should see UDP on port 123.

---

## ✅ Setup: Chrony Client (Ubuntu)

### 1. **Install Chrony**

```bash
sudo apt update
sudo apt install chrony -y
```

### 2. **Configure to Use Local NTP Server**

Edit the config:

```bash
sudo nano /etc/chrony/chrony.conf
```

Comment out or remove any existing `server` lines and add your NTP server IP:

```conf
server 192.168.1.10 iburst
```

Replace `192.168.1.10` with the actual NTP server IP.

---

### 3. **Restart and Enable Chrony**

```bash
sudo systemctl restart chrony
sudo systemctl enable chrony
```

---

### 4. **Verify Sync with NTP Server**

```bash
chronyc sources -v
chronyc tracking
```

You should see your server listed and marked as the current source.

---

## ✅ Firewall (Optional)

Allow UDP port 123 on both server and client:

```bash
sudo ufw allow 123/udp
```

---

## ✅ System Clock Sync Check

```bash
timedatectl status
```

Should show: `System clock synchronized: yes`

---
