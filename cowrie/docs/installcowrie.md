Ubuntu 24.04
---

### Change default SSH port and restart SSH service

```bash
sudo sed -i 's/^#\?Port .*/Port 2200/' /etc/ssh/sshd_config
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart ssh
```
#### Verify:
```bash
sudo lsof -i :2200
```
#### Avoid ssh in cowrie:
```bash
ssh -p 2200 user@ip
```

---

### Install required packages for Cowrie

```bash
sudo apt-get install git python3-venv libssl-dev libffi-dev build-essential libpython3-dev python3-minimal authbind -y
```

---

### Create dedicated user `cowrie`

```bash
sudo adduser --disabled-password --gecos "" cowrie
```

```bash
sudo su - cowrie
```

---

### Clone Cowrie repo and enter directory

```bash
git clone http://github.com/cowrie/cowrie
```

```bash
cd cowrie
```

---

### Setup Python virtual environment and install dependencies

```bash
python3 -m venv cowrie-env
```

```bash
source cowrie-env/bin/activate
```

```bash
python3 -m pip install --upgrade pip
```

```bash
python3 -m pip install --upgrade -r requirements.txt
```

---

### Copy config and apply modifications

```bash
cp etc/cowrie.cfg.dist etc/cowrie.cfg
```

```bash
sed -i '0,/^hostname = .*/s/^hostname = .*/hostname = root/' etc/cowrie.cfg
```

```bash
sed -i '0,/^timezone = .*/s/^timezone = .*/timezone = system/' etc/cowrie.cfg
```

```bash
sed -z -i 's/# Enable Telnet support, disabled by default\nenabled = false/enabled = true/' etc/cowrie.cfg
```

---

### Create `userdb.txt` for login rules

```bash
cat > etc/userdb.txt << "EOF"
root:x:!root
root:x:!123456
root:x:!/honeypot/i
root:x:*
*:x:*
EOF
```

---

### Exit cowrie user and set iptables port redirection

```bash
exit
```

```bash
sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
```

```bash
sudo iptables -t nat -A PREROUTING -p tcp --dport 23 -j REDIRECT --to-port 2223
```

---

### Install iptables-persistent package (choose yes on prompt)

```bash
sudo apt install iptables-persistent -y
```

---

### Switch back to cowrie user

```bash
sudo su - cowrie
```

---

### Start Cowrie honeypot and tail logs

```bash
cd cowrie
```

```bash
source cowrie-env/bin/activate
```

```bash
bin/cowrie start
```

```bash
tail -f var/log/cowrie/cowrie.log
```

---

### Prepare systemd user service setup

```bash
bin/cowrie stop
```

```bash
exit
```

```bash
sudo loginctl enable-linger cowrie
```

---

### Install systemd-container and open shell in cowrie user container

```bash
sudo apt install systemd-container -y
```

```bash
sudo machinectl shell cowrie@
```

---

### Create systemd user service file for Cowrie

```bash
mkdir -p ~/.config/systemd/user
```

```bash
cat > ~/.config/systemd/user/cowrie.service << EOF
[Unit]
Description=Cowrie SSH and Telnet honeypot service (User)
After=network.target
Requires=cowrie.socket

[Service]
Type=simple
Environment=PYTHONPATH=/home/cowrie/cowrie/src
WorkingDirectory=/home/cowrie/cowrie

ExecStart=/home/cowrie/cowrie/cowrie-env/bin/python /home/cowrie/cowrie/cowrie-env/bin/twistd --umask 0022 --nodaemon --pidfile= -l - cowrie

Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
```

---

### Create systemd user socket file for Cowrie

```bash
cat > ~/.config/systemd/user/cowrie.socket << EOF
[Unit]
Description=Cowrie SSH and Telnet honeypot socket (User)
PartOf=cowrie.service

[Socket]
ListenStream=2222
ListenStream=2223

[Install]
WantedBy=sockets.target
EOF
```

---

### Configure Cowrie to use systemd sockets for SSH and Telnet

```bash
cd ~/cowrie
```

```bash
sed -i 's/^listen_endpoints = tcp:2222:interface=0.0.0.0/listen_endpoints = systemd:domain=INET6:index=0/' etc/cowrie.cfg
```

```bash
sed -i 's/^listen_endpoints = tcp:2223:interface=0.0.0.0/listen_endpoints = systemd:domain=INET6:index=1/' etc/cowrie.cfg
```

---

### Reload systemd user daemon, enable and start Cowrie socket and service

```bash
systemctl --user daemon-reload
```

```bash
systemctl --user enable cowrie.socket cowrie.service
```

```bash
systemctl --user start cowrie.socket cowrie.service
```

---

### Verify Cowrie service status and logs

```bash
systemctl --user status cowrie
```

```bash
journalctl --user -u cowrie -f
```

```bash
sudo journalctl -u "user@$(id -u cowrie).service" -f
```

---

If you want me to export this into a file or format it differently, just say!
