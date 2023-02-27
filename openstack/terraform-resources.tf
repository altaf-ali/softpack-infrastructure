variable "prefix" {}
variable "ssh_key" {}
variable "ssh_key_name" {}

variable "infoblox_zone" {}
variable "infoblox_dns_view" {}

#-------------------------------------------------------------------------------
# create keypair

resource "openstack_compute_keypair_v2" "public-key" {
  name       = var.ssh_key_name
  public_key = file(var.ssh_key)
}

#-------------------------------------------------------------------------------
# create resources for build controller

variable "build_controller_image" {}
variable "build_controller_flavor" {}

resource "openstack_compute_instance_v2" "build-controller" {
  name        = "${var.prefix}-build-controller"
  image_name  = var.build_controller_image
  flavor_name = var.build_controller_flavor
  key_pair    = openstack_compute_keypair_v2.public-key.name
  network {
    name = "cloudforms_network"
  }
  security_groups = [
    "cloudforms_icmp_in",
    "cloudforms_ssh_in",
    "cloudforms_web_in"
  ]
}

resource "openstack_networking_floatingip_v2" "build-controller-ip" {
  pool        = "public"
  description = "${var.prefix}-build-controller-ip"
}

resource "openstack_compute_floatingip_associate_v2" "build-controller-ip" {
  floating_ip = openstack_networking_floatingip_v2.build-controller-ip.address
  instance_id = openstack_compute_instance_v2.build-controller.id
}

resource "infoblox_a_record" "build-controller-a-record" {
  dns_view = var.infoblox_dns_view
  fqdn     = "${var.prefix}-build-controller.${var.infoblox_zone}"
  ip_addr  = openstack_networking_floatingip_v2.build-controller-ip.address
}

#-------------------------------------------------------------------------------
# create resources for build node(s)

variable "build_node_count" {}
variable "build_node_image" {}
variable "build_node_flavor" {}

locals {
  build_nodes = {
    for i in range(var.build_node_count) : i => format("build-node-%02d", i+1)
  }
}

resource "openstack_compute_instance_v2" "build-node" {
  count       = var.build_node_count
  name        = "${var.prefix}-${values(local.build_nodes)[count.index]}"
  image_name  = var.build_node_image
  flavor_name = var.build_node_flavor
  key_pair    = openstack_compute_keypair_v2.public-key.name
  network {
    name = "cloudforms_network"
  }
  security_groups = [
    "cloudforms_icmp_in",
    "cloudforms_ssh_in"
  ]
}

resource "openstack_networking_floatingip_v2" "build-node-ip" {
  count       = var.build_node_count
  pool        = "public"
  description = "${var.prefix}-${values(local.build_nodes)[count.index]}-ip"
}

resource "openstack_compute_floatingip_associate_v2" "build-node-ip" {
  count       = var.build_node_count
  floating_ip = "${element(openstack_networking_floatingip_v2.build-node-ip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.build-node.*.id, count.index)}"
}

resource "infoblox_a_record" "build-node-a-record" {
  count    = var.build_node_count
  dns_view = var.infoblox_dns_view
  fqdn     = "${var.prefix}-${values(local.build_nodes)[count.index]}.${var.infoblox_zone}"
  ip_addr  = "${element(openstack_networking_floatingip_v2.build-node-ip.*.address, count.index)}"
}
