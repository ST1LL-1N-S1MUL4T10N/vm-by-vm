https://github.com/iagox86/dnscat2

---

**1. Update system and install required packages**

```bash
sudo apt update && sudo apt upgrade -y
```

```bash
sudo apt install bind9 bind9utils bind9-doc python3-pip git -y
```

---

**2. Enable IP forwarding temporarily and persistently**

```bash
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
```

```bash
sudo sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
```

```bash
sudo sysctl -p
```

---

**3. Edit BIND configuration options**

```bash
sudo nano /etc/bind/named.conf.options
```

*Inside the file, set:*

```
recursion no;
allow-query { any; };
listen-on { any; };
listen-on-v6 { any; };
```

---

**4. Create zone configuration and zone file for your domain**

```bash
sudo nano /etc/bind/named.conf.local
```

*Add zone block like:*

```
zone "examplec2.com" {
  type master;
  file "/etc/bind/db.examplec2.com";
};
```

```bash
sudo cp /etc/bind/db.local /etc/bind/db.examplec2.com
```

```bash
sudo nano /etc/bind/db.examplec2.com
```

*Replace localhost with ns1.examplec2.com and add your C2 records*

---

**5. Restart and enable BIND service**

```bash
sudo systemctl restart bind9
```

```bash
sudo systemctl enable bind9
```

---

**6. Clone and set up the DNS tunneling C2 framework**

```bash
git clone https://github.com/iagox86/dnscat2.git
```

```bash
cd dnscat2/server
```

```bash
sudo gem install bundler
```

```bash
bundle install
```

---

**7. Start the DNS C2 server**

```bash
ruby ./dnscat2.rb --dns examplec2.com
```

---

**8. Open firewall ports for DNS traffic**

```bash
sudo ufw allow 53/udp
```

```bash
sudo ufw allow 53/tcp
```

```bash
sudo ufw reload
```

---


