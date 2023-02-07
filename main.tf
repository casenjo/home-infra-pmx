terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9.11"
    }
  }
}

provider "proxmox" {
  pm_api_url  = var.proxmox_api_url
  pm_password = var.proxmox_password
  pm_user     = var.proxmox_user
  # pm_log_enable = true
  # pm_log_file = "terraform-plugin-proxmox.log"
  # pm_log_levels = {
  #   _default = "debug"
  #   _capturelog = ""
  # }
}

# resource <type> <label>
resource "proxmox_lxc" "base-template-ubuntu-22-04" {
  target_node  = "proxmox"

  vmid = 666
  # As seen through Proxmox UI
  # Resources
  memory       = 1024
  swap         = 512
  cores = 1

  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  # Network
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
    hwaddr = var.golden_image_mac_address
  }

  # DNS
  hostname     = "base-template-ubuntu-22-04"
  nameserver   = var.nameserver

  # Proxmox
  ostemplate    = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  ostype        = "ubuntu"
  password      = var.golden_image_root_password
  unprivileged  = true
  onboot        = true
  startup       = "order=1"
  cpulimit      = 0

  ssh_public_keys = var.ssh_public_key

  # template = true

  start = true

  provisioner "local-exec" {
    command = "ansible-playbook -i ansible/inventory.yaml ansible/pb_golden_image.yaml"
  }
}

resource "proxmox_lxc" "pihole-test" {
  target_node   = "proxmox"
  clone         = "666"
  full          = true

  # As seen through Proxmox UI
  # Resources
  memory        = 1024
  swap          = 512
  cores         = 1
  hostname      = "pihole-test"
  nameserver    = var.nameserver


  # If you don't include the rootfs storage Terraform crashes
  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  depends_on = [
    proxmox_lxc.base-template-ubuntu-22-04
  ]

  # Network
  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
    hwaddr = var.pihole_mac_address
  }

  # Proxmox
  unprivileged = true
  onboot = true
  startup = "order=1"

  start = true

  provisioner "local-exec" {
    command = "ansible-playbook -i ansible/inventory.yaml ansible/pb_container_docker_host.yaml"
  }
}