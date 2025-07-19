https://sankalppatil12112001.medium.com/bettercap-basics-your-ultimate-guide-to-network-penetration-testing-1d6b087a8f31

# run the tool with:
```
sudo bettercap
```
## Common Commands:

### Show available modules:
```
help
```
### List network interfaces:
```
net.show
```
### Set a target:
```
set net.recon.targets 192.168.1.0/24
```
### Start network reconnaissance:
```
net.recon on
```

## Key Features and Use Cases:
### ARP Spoofing

Intercept and manipulate traffic between devices on the network.
```
set arp.spoof.targets 192.168.1.10
arp.spoof on
```
2. DNS Spoofing

Redirect DNS queries to a malicious IP.
```
set dns.spoof.domains example.com
set dns.spoof.address 192.168.1.100
dns.spoof on
```
3. Wi-Fi Hacking

Bettercap supports Wi-Fi attacks like deauth and probe request monitoring.
```
wifi.recon on
wifi.assoc on
```
