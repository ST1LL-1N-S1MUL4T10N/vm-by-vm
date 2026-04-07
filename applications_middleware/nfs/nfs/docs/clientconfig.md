#### TLDR: On the client side mount the share:

```bash
sudo apt install -y nfs-common
sudo mount 172.16.110.213:/home/nfsshare /mnt
```



---



## NFS Client Setup Guide

### Step 1: Install NFS client utilities

```bash
sudo apt update
sudo apt install -y nfs-common
```

---

### Step 2: Create a mount point

Pick or create a directory where you want to mount the NFS share, e.g.:

```bash
sudo mkdir -p /mnt/nfsshare
```

---

### Step 3: Mount the NFS share manually

```bash
sudo mount 172.16.110.213:/home/nfsshare /mnt/nfsshare
```

* Replace `172.16.110.213` with your NFS server IP.
* Replace `/home/nfsshare` with the exported path on the server.
* Replace `/mnt/nfsshare` with your local mount point.

---

### Step 4: Verify the mount

```bash
mount | grep nfsshare
```

Or

```bash
df -h /mnt/nfsshare
```

You should see the mounted NFS share.

---

### Step 5: Access the files

Just `cd /mnt/nfsshare` and use the files normally.

---

### Step 6: Unmount the NFS share

When done, unmount with:

```bash
sudo umount /mnt/nfsshare
```

---

### Optional: Auto-mount at boot via `/etc/fstab`

If you want the NFS share to mount automatically on boot:

1. Edit `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

2. Add this line at the end:

```
172.16.110.213:/home/nfsshare  /mnt/nfsshare  nfs  defaults  0  0
```

3. Save and exit.

4. Test mounting all entries in fstab:

```bash
sudo mount -a
```

If errors, read the guide again or ask chatGPT.

---
