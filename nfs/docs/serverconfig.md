
### Step 1: Install NFS server packages

```bash
sudo apt update
sudo apt install -y nfs-kernel-server
```

---

### Step 2: Prepare your export directory

Create a directory to share, e.g., `/home/nfsshare`

```bash
sudo mkdir -p /home/nfsshare
sudo chown nobody:nogroup /home/nfsshare
sudo chmod 755 /home/nfsshare
```

---

### Step 3: Configure exports

Edit `/etc/exports`:

```bash
sudo nano /etc/exports
```

Add this line (sharing `/home/nfsshare` with network):

```
/home/nfsshare 172.16.110.0/24(rw,no_root_squash,sync,no_subtree_check)
```

* `172.16.110.0/24` assumes client IPs will be in this subnet.
* `rw` gives read-write access.
* `no_root_squash` allows root on client to have root access (remove this for security).
* `sync` makes sure writes are committed before reply.
* `no_subtree_check` disables subtree checking for simplicity.

Save and exit.

---

### Step 4: Export the shares

```bash
sudo exportfs -a
```

---

### Step 5: Start and enable NFS server

```bash
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server
```

---

### Step 6: Verify export

```bash
sudo exportfs -v
```

You should see the share listed.

---


**That’s the bare minimum.**



