
---

# 🔒 UFW Configuration Guide (Client VM → Dante Proxy)

**Purpose:** Restrict the client VM so that all traffic is blocked except SSH (22/tcp) and outbound Dante SOCKS5 (1080/tcp).

---

## 1. Reset Existing Rules

```bash
sudo ufw reset
```

---

## 2. Set Default Policies

```bash
sudo ufw default deny incoming
sudo ufw default deny outgoing
```

---

## 3. Allow SSH (22/tcp)

```bash
sudo ufw allow 22/tcp
```

---

## 4. Allow Outbound Dante SOCKS5 (1080/tcp)

Dante server IP: `192.168.0.168`

```bash
sudo ufw allow out to 192.168.0.168 port 1080 proto tcp
```

---

## 5. Enable UFW

```bash
sudo ufw enable
sudo ufw status verbose
```

Expected output:

```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
192.168.0.168 1080/tcp     ALLOW OUT   Anywhere
```

---

## 6. Verification

* **Ping test (ICMP blocked):**

```bash
ping -c 2 1.1.1.1
```

* **Direct TCP test (blocked):**

```bash
curl https://ifconfig.me
```

* **TCP via Dante (allowed):**

```bash
curl -x socks5://192.168.0.168:1080 https://ifconfig.me
```

* **SSH connectivity:** Allowed.

---

**Result:** Client VM is restricted to:

* SSH access only
* Outbound connections exclusively through Dante SOCKS5

---
