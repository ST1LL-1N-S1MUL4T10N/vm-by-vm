terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc03"
    }
  }
}

provider "proxmox" {
  pm_api_url                  = "https://192.168.0.192:8006/api2/json"
  pm_api_token_id             = "terraform-prov@pve!mytoken"
  pm_api_token_secret         = "f42bc0b4-uvwm-this-bad4-55b36595c939"
  pm_tls_insecure             = true
  pm_parallel                 = 1
  pm_log_enable               = false
  pm_timeout                  = 600
  pm_minimum_permission_check = false
}

resource "proxmox_vm_qemu" "vm-instance" {
  name        = "vm-instance"
  target_node = "pve"
  clone       = "base"          # Use the template name, not VMID
  full_clone  = true
  memory      = 2048

  cpu {
    cores = 1
  }

  disk {
    slot    = "scsi0"
    size    = "32G"
    storage = "local-lvm"
    type    = "disk"
    discard = true
  }

  network {
    id       = 0
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  scsihw    = "virtio-scsi-pci"
  bootdisk  = "scsi0"
  boot      = "c"

  ciuser     = "bot"
  cipassword = "bot"
  ipconfig0  = "ip=dhcp"

  agent      = 1   # QEMU guest agent enabled
}
