
---

# Dante Setup on Ubuntu VM

## **VM Info**

* IP: `192.168.0.168`
* Interface: `ens18`

---

## **1. Install Dante**

```bash
sudo apt update
sudo apt install dante-server
```
### (optional)
```bash
export PATH=$PATH:/usr/sbin  # only if needed (Debian)
danted -v                     # verify version
```

---

## **2. Configure Dante**

### **2.1 Backup old config**

```bash
sudo mv /etc/danted.conf /etc/danted.conf.bak
```

### **2.2 Create new config**

```bash
sudo nano /etc/danted.conf
```

Paste:

```conf
logoutput: /var/log/socks.log
internal: ens18 port = 1080
external: ens18
clientmethod: none
socksmethod: none
user.privileged: root
user.notprivileged: nobody

client pass {
        from: 192.168.0.0/24 to: 0.0.0.0/0
        log: error connect disconnect
}
client block {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        log: connect error
}
socks pass {
        from: 192.168.0.0/24 to: 0.0.0.0/0
        log: error connect disconnect
}
socks block {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        log: connect error
}
```

> Only allow the `192.168.0.0/24` subnet. All other clients are blocked.

### **2.3 Enable Dante logging permissions**

```bash
sudo nano /lib/systemd/system/danted.service
```

Add:

```ini
[Service]
ReadWriteDirectories=/var/log
```

Reload systemd and start Dante:

```bash
sudo systemctl daemon-reload
sudo systemctl start danted
sudo systemctl enable danted
sudo systemctl status danted
```

---

## **3. Client VM Setup with Proxychains**

* Client VM IP: `192.168.0.177`

### **3.1 Install via SOCKS proxy (if `proxychains4` not default)**

Create `/etc/apt/apt.conf.d/95proxies`:

```bash
sudo nano /etc/apt/apt.conf.d/95proxies
```

Add:

```
Acquire::http::Proxy "socks5h://192.168.0.168:1080/";
Acquire::https::Proxy "socks5h://192.168.0.168:1080/";
```

Then:

```bash
sudo apt update
sudo apt install proxychains4 -y
```

### **3.2 Configure Proxychains**

```bash
sudo nano /etc/proxychains4.conf
```

At the bottom `[ProxyList]`, add:

```
socks5  192.168.0.168 1080
```

> `socks5` is used; DNS handled through the proxy if configured.

### **3.3 Test Proxychains**

```bash
proxychains4 curl https://ifconfig.me
```

Expected output: `Dante server’s external IP`

### **3.4 Use Proxychains for Applications**

Examples:

```bash
proxychains4 nc -vz google.com 443
proxychains4 sudo apt install nmap
proxychains4 sudo apt update
```

> UDP traffic may not work without additional configuration. Proxychains4 not needed, if /etc/apt/apt.conf.d/95proxies set.

---

## **4. Debug Steps**

On Dante server (`192.168.0.168`):

```bash
sudo tail -f /var/log/socks.log
```

Test connection to Dante:

```bash
nc -zv 192.168.0.168 1080
```

---
