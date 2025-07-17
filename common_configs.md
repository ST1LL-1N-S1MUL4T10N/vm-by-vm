#

## Proxmox Post Install Clean Up:
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"
```
## Ubuntu netplan Teamplate:
```
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.101.100/24
      routes:
        - to: 0.0.0.0/0
          via: 192.168.101.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
```
