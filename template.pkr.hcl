
variable "HTTP_IP" {
  type    = string
  default = "webserver.testnet.lan"
}

variable "HTTP_PATH" {
  type    = string
  default = "/deploy/template-kickstart/kickstart.ks"
}

variable "version" {
  type    = string
  default = "0.0.1"
}

# Set certain variables to reside to ENV vars so we can vault them in gitlab

variable "vcenter_username" {
  type    = string
  default = env("VCENTER_USERNAME")
}

variable "vcenter_cluster" {
  type = string
  default = env("VCENTER_CLUSTER")
}

variable "vcenter_datacenter" {
  type = string
  default = env("VCENTER_DATACENTER")
}

variable "vcenter_esx_host" {
  type = string
  default = env("VCENTER_ESX_HOST")
}

variable "vcenter_url" {
  type = string
  default = env("VCENTER_URL")
}

variable "vcenter_datastore" {
  type = string
  default = env("VCENTER_DATASTORE")
}

variable "vcenter_iso_location" {
  type    = string
  default = env("VCENTER_ISO_LOCATION")
}

variable "vcenter_folder" {
  type = string
  default = env("VCENTER_FOLDER")
}

variable "vcenter_password" {
  type = string
  default = env("VCENTER_PASSWORD")
  sensitive = true
}

variable "vm_username" {
  type = string
  default = env("VM_USERNAME")
}
variable "vm_password" {
  type = string
  default = env("VM_PASSWORD")
  sensitive = true
}

variable "vm_network" {
  type = string
  default = env("VM_NETWORK")
}

variable "vm_disk_size" {
  type = number
  default = env("VM_DISK_SIZE")
}

variable "vm_name" {
  type = string
  default = env("VM_NAME")
}
source "vsphere-iso" "almalinux8" {
  CPU_hot_plug         = true
  CPUs                 = 2
  RAM                  = 2048
  RAM_hot_plug         = true
  firmware             = "efi"
  boot_command         = ["<up>e<wait><down><down><end><spacebar>text ip=dhcp inst.ks=http://${var.HTTP_IP}${var.HTTP_PATH}<wait><wait><leftCtrlOn>x<leftCtrlOff>"]
  # boot_command         = ["<up><tab> text ip=dhcp inst.ks=http://${var.HTTP_IP}${var.HTTP_PATH}<enter><wait><enter>"] # this one works with normal bios
  cluster              = "${var.vcenter_cluster}"
  convert_to_template  = true
  create_snapshot      = false
  datacenter           = "${var.vcenter_datacenter}"
  datastore            = "${var.vcenter_datastore}"
  disk_controller_type = ["pvscsi"]
  folder               = "${var.vcenter_folder}"
  guest_os_type        = "centos8_64Guest"
  host                 = "${var.vcenter_esx_host}"
  insecure_connection  = "true"
  iso_paths            = ["${var.vcenter_iso_location}"]
  network_adapters {
    network      = "${var.vm_network}"
    network_card = "vmxnet3"
  }
  notes            = "template ${var.vm_name} ${var.version}"
  shutdown_command = "/sbin/halt -h -p"
  ssh_username     = "${var.vm_username}"
  ssh_password     = "${var.vm_password}"
  storage {
    disk_size             = "${var.vm_disk_size}"
    disk_thin_provisioned = true
  }
  username       = "${var.vcenter_username}"
  password         = "${var.vcenter_password}"
  vcenter_server = "${var.vcenter_url}"
  vm_name        = "${var.vm_name}"
}

build {
  sources = ["source.vsphere-iso.almalinux8"]

    provisioner "ansible" {
      playbook_file = "/app/playbook.yml"
      ansible_ssh_extra_args = ["-o IdentitiesOnly=no -o PubkeyAcceptedKeyTypes=+ssh-rsa -o HostKeyAlgorithms=+ssh-rsa"]
    }
}
