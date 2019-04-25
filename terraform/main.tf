// Licensed under the Universal Permissive License v 1.0

resource "opc_compute_ssh_key" "primary" {
    name    = "oracle-key"
    key     = "${file(var.ssh_public_key)}" 
    enabled = true
}

resource "opc_compute_ip_reservation" "panda-ip-reservation" {
  parent_pool = "/oracle/public/ippool"
  permanent   = true
}

resource "opc_compute_instance" "instance" {
  name                = "${var.instance_name}"
  hostname            = "${length(var.instance_hostname) > 0 ? var.instance_hostname : var.instance_name}"
  label               = "${length(var.instance_label) > 0 ? var.instance_label : var.instance_name}"
  shape               = "${var.instance_shape}"
  instance_attributes = "${var.instance_attributes}"
  reverse_dns         = "${var.reverse_dns}"
  ssh_keys            = ["${opc_compute_ssh_key.primary.name}"] 
  tags                = "${var.tags}"

  networking_info {
    index          = 0
    shared_network = "${var.ip_network == "" ? true : false}"
    ip_network     = "${var.ip_network}"
    nat            = ["${opc_compute_ip_reservation.panda-ip-reservation.name}"]
    dns            = "${var.dns}"
    search_domains = "${var.search_domains}"
  }

  storage {
    index  = 1
    volume = "${opc_compute_storage_volume.boot-volume.name}"
  }

  boot_order = [1]
}

resource "opc_compute_storage_volume" "boot-volume" {
  name             = "${var.instance_name}-boot"
  description      = "${var.instance_name} boot storage volume "
  image_list       = "${var.boot_volume_image_list}"
  image_list_entry = "${var.boot_volume_image_list_entry}"
  size             = "${var.boot_volume_size}"
  bootable         = true
  tags             = "${var.tags}"
}
