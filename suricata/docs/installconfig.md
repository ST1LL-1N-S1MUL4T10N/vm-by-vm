
---

## Suricata Installation and Setup on Ubuntu 24.04

### Step 1: Add the Suricata Stable PPA Repository

```bash
sudo add-apt-repository ppa:oisf/suricata-stable
```

### Step 2: Update Package Lists

```bash
sudo apt update
```

### Step 3: Install Suricata

```bash
sudo apt install suricata
```

### Step 4: Stop the Suricata Service

```bash
sudo systemctl stop suricata
```

### Step 5: Edit Suricata Configuration File

```bash
sudo nano /etc/suricata/suricata.yaml
```

> * Set `HOME_NET` appropriately (e.g., `HOME_NET: "[192.168.1.0/24]"`)
> * Use `Ctrl + W` to find and replace `eth0` with correct network interface name
> * Save and exit (`Ctrl + O`, `Enter`, `Ctrl + X`)

### Step 6: Test Suricata Configuration

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml -v
```

> If it reports no rules found, continue to the next steps.

### Step 7: Create Rules Directory

```bash
sudo mkdir -p /var/lib/suricata/rules
```

### Step 8: Change to Rules Directory

```bash
cd /var/lib/suricata/rules/
```

### Step 9: Create and Edit Rules File

```bash
sudo nano suricata.rules
```

> Paste the following rules into the file:

```rules
alert icmp any any -> $HOME_NET any (msg:"U GOT PINGED!!!"; sid:100001; rev:1;)

alert tcp/udp any any -> $HOME_NET any (msg:"Your message here!"; sid:next_number; rev:1;)

# Honeypot
alert tcp any any -> $HOME_NET 22 (msg:"SOMEONE TRAPPED IN HONEYPOT!!!"; sid:100001; rev:1;)

# SSH
alert tcp any any -> $HOME_NET 2200 (msg:"SSH ATTEMPT TO REAL HOST DETECTED!!!"; sid:100002; rev:1;)

# DNS
alert udp any any -> $HOME_NET 53 (msg:"[DNS] Query to Local DNS Server"; sid:100003; rev:1;)

# DHCP
alert udp any 67 -> $HOME_NET 68 (msg:"[NET] DHCP Offer Detected"; sid:100004; rev:1;)

# netboot.xyz
alert udp any any -> $HOME_NET 69 (msg:"SOMEONE IS USING [NETBOOT]"; sid:100008; rev:1;)
```

> Save and exit.

### Step 10: Test Suricata Configuration Again

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml -v
```

### Step 11: Start Suricata Service

```bash
sudo systemctl start suricata
```

### Step 12: Enable Suricata Service at Boot

```bash
sudo systemctl enable suricata
```

### Step 13: Check Suricata Service Status

```bash
sudo systemctl status suricata
```

---
