// Copyright © 2017 Oracle and/or its affiliates.  All rights reserved.
// Licensed under the Universal Permissive License v 1.0

variable user {
  description = "OCI Classic username"
}

variable password {
  description = "OCI Classic pawword"
}

variable domain {
  description = "Domain ID"
}

variable endpoint {
  description = "REST Endpoint"
//  default = "https://compute.uscom-east-1.oraclecloud.com"
//  default = "https://compute.uscom-central-1.oraclecloud.com"
//  default = "https://compute.brcom-central-1.oraclecloud.com"
}

variable ssh_public_key {
  default = "~/.ssh/id_rsa.pub"
  description = "SSH public key PATH"
}

variable boot_volume_image_list {
  description = "The Image to use for the boot volume for Migration"
  default     = "/oracle/public/OL_7.5_UEKR4_x86_64_MIGRATION"
}

variable boot_volume_image_list_entry {
  description = "(Optional) The Image List Entry to use for the boot volume."
  default     = 1
}

variable boot_volume_size {
  description = "Size in GB of the boot storage volume. Max size is 2000"
  default = 20
}

variable instance_name {
  description = "Migration instance name"
  default = "Panda"
}

variable instance_hostname {
  default     = "Panda"
}

variable instance_label {
  default     = "Panda"
}

variable instance_shape {
  description = "Instance shape: oc3, oc2m, oc3m, etc"
}

variable instance_attributes {
  description = "(Optional) A JSON string of custom attributes."
  default     = ""
}

variable reverse_dns {
  description = "(Optional) create reverse DNS records."
  default     = true
}

variable ip_network {
  description = "(Optional) IP Network to attach the instance to. If not set the instance will be connected to the Shared Network."
  default     = ""
}

variable ip_reservation {
  description = "(Optional) IP Address Reservation. If an `ip_network` is set then this must be a reference to an `opc_compute_ip_address_reservervation`.  If no IP Network is set then this must be a `opc_compute_ip_address_reservervation`."
  default     = ""
}

variable dns {
  type        = "list"
  description = "(Optional) List of DNS servers."
  default     = []
}

variable search_domains {
  type        = "list"
  description = "(Optional) Search domains."
  default     = []
}

variable tags {
  type        = "list"
  description = "(Optional) list of tags to apply to all resources."
  default     = []
}
