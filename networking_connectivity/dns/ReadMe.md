# 🌐 [[technitium]] [[DNS]] 

**Source**: https://www.youtube.com/watch?v=m3lNqy3HAvA

---

### ⚙️ Setup Flow: DNS via Docker

1. **Docker install**
   → base platform for DNS container

2. **systemd conflict**
   → `systemd-resolved` ➝ `disable` to avoid port 53 bind issue

3. **5380 webport**
   → admin GUI access (`http://<IP>:5380`)

4. **DNS config**
   → `netplan` preferred over `resolv.conf`
   → edit DNS in `/etc/netplan/*.yaml`

5. **Static IP config**
   → edit `/etc/network/interfaces` 

---

### 🔁 DNS Setup & Flow

1. **DNS Zone:**
   → defines namespace scope (e.g., `example.com`)

2. **DNS Record:**
   → entries in zone (e.g., `A`, `CNAME`, `MX`)

3. **DNS Forwarder:**
   → forwards unresolved queries (e.g., `8.8.8.8`)

4. **Clients Registered:**
   → clients set DNS IP (static/DHCP/DDNS)

5. **Tests:**

   * `dig fqdn` ✅?
   * `nslookup fqdn` ✅?
   * `ping domain` ✅?
   * `dig -x ip` ✅?
   * `cat /etc/resolv.conf` → DNS IP?

---
