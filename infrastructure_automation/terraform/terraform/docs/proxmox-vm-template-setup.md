
# ⚡ Step-by-Step Setup of VM Template in Proxmox CLI ⚡

---

## 1️⃣ Verify VM

```bash
qm list
````

* ✅ VM 420 exists as `base`, Ubuntu 24.04, stopped, 32GB disk, 4GB RAM.

---

## 2️⃣ Add Cloud-Init Drive

```bash
qm set 420 --ide2 local-lvm:cloudinit
```

* 💾 Dedicated cloud-init drive added (required for user/network injection).

---

## 3️⃣ Set Boot Disk and Order

```bash
qm set 420 --boot c --bootdisk scsi0
```

* 🖥️ Boot set to primary disk.

---

## 4️⃣ Configure CPU and RAM

```bash
qm set 420 --memory 4096
qm set 420 --cores 2
```

* ⚙️ Resources: 4GB RAM, 2 CPU cores.

---

## 5️⃣ Configure Networking

```bash
qm set 420 --net0 virtio,bridge=vmbr0
```

* 🌐 NIC configured with `virtio`, bridged to `vmbr0`.

Optional static IP:

```bash
qm set 420 --ipconfig0 ip=192.168.0.150/24,gw=192.168.0.1
```

---

## 6️⃣ Set Cloud-Init User

```bash
qm set 420 --ciuser bot --cipassword 'bot'
```

* 👤 Default user/password configured.

Optional SSH key:

```bash
qm set 420 --sshkey "$(cat ~/.ssh/id_rsa.pub)"
```

---

## 7️⃣ Enable QEMU Guest Agent

```bash
qm set 420 --agent 1
```

* 🤖 QEMU Guest Agent enabled (for IP and state queries).

---

## 8️⃣ Start VM & Install Guest Agent (Inside VM)

```bash
qm start 420
qm terminal 420
```

Inside VM:

```bash
sudo apt update
sudo apt install -y qemu-guest-agent cloud-init cloud-initramfs-growroot
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent
```

* 🚀 Guest Agent installed and running.

---

## 9️⃣ Verify IP via Guest Agent

```bash
qm guest cmd 420 network-get-interfaces
```

* 🌍 DHCP IP returned (e.g., `192.168.0.18`). Networking verified.

---

## 🔟 Convert VM to Template

```bash
qm shutdown 420
qm template 420
```

* 🏗️ VM 420 converted to a **template** (`base`) for cloning.

---

## ✅ Result

* Reusable **Ubuntu 24.04 cloud-init template** with:

  * 💾 Cloud-init drive and user
  * 🌐 Networking
  * 🤖 QEMU guest agent
  * 🖥️ Boot settings

* Ready for Terraform or CLI cloning.

---
