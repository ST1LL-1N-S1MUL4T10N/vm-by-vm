#!/bin/bash

REMOTE_IP="172.16.110.222"
USER="base"
NETWORK_PREFIX="172.16.110"
GATEWAY="$NETWORK_PREFIX.1"

# Ask for last octet
read -p "Enter the last octet for the static IP: " LAST_OCTET

# Validate input
if ! [[ "$LAST_OCTET" =~ ^[0-9]+$ ]] || [ "$LAST_OCTET" -lt 1 ] || [ "$LAST_OCTET" -gt 254 ]; then
    echo "Invalid octet. Must be 1-254."
    exit 1
fi

STATIC_IP="$NETWORK_PREFIX.$LAST_OCTET/24"

echo "You are about to set the IP to $STATIC_IP on $REMOTE_IP."
echo "You will be prompted for your remote password and sudo password."

# SSH into remote server, write netplan, apply, and reboot
ssh -t "$USER@$REMOTE_IP" "sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: no
      addresses:
        - $STATIC_IP
      routes:
        - to: 0.0.0.0/0
          via: $GATEWAY
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
EOF
sudo netplan apply
echo 'Netplan applied. The system will now reboot.'
sudo reboot
"

echo "Remote reboot triggered. Terminal returned."
exit 0
