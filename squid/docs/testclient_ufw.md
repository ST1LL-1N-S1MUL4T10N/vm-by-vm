
---

# 🔒 UFW Configuration Guide

**Goal:** Configure UFW on a client VM so that **all network traffic is blocked** except:

* **SSH (22/tcp)** for remote management
* **Squid Proxy (3128/tcp)** for outbound web traffic

---

## **1. Reset Existing Rules**

It’s best to start clean:

```bash
sudo ufw reset
```

This disables UFW and removes all existing rules.

---

## **2. Set Default Policies**

By default, UFW allows outgoing traffic. We want to **block everything by default**:

```bash
sudo ufw default deny incoming
sudo ufw default deny outgoing
```

* **deny incoming** → No one can connect in, unless explicitly allowed
* **deny outgoing** → The client cannot connect out, unless explicitly allowed

---

## **3. Allow SSH (22/tcp)**

So you don’t lose remote access:

```bash
sudo ufw allow 22/tcp
```

---

## **4. Allow Outbound Access to Squid Proxy (3128/tcp)**

If your Squid proxy runs on the same VM:

```bash
sudo ufw allow out 3128/tcp
```

If your Squid proxy is on another server (recommended), restrict by IP:

```bash
sudo ufw allow out to <proxy_ip> port 3128 proto tcp
```

Replace `<proxy_ip>` with the IP of your Squid proxy server.

---

## **5. Enable UFW**

Activate the firewall:

```bash
sudo ufw enable
```

Check status:

```bash
sudo ufw status verbose
```

Expected result:

```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
3128/tcp                   ALLOW OUT   <proxy_ip>
```

---

## **6. Verification**

* **Ping test:**

  ```bash
  ping -c 2 1.1.1.1
  ```

  → Should fail.

* **Web test through proxy:**

  ```bash
  curl -x http://<proxy_ip>:3128 https://ifconfig.me
  ```

  → Should succeed and return your external IP.

* **SSH test:**
  Remote SSH into the VM should still work.

---

✅ **Result:**
The client VM is **isolated from the Internet**. It can only:

* Accept SSH connections
* Send HTTP/HTTPS requests through the Squid proxy

---

Do you want me to also include an **iptables equivalent version** of this guide for cases where UFW isn’t installed?
