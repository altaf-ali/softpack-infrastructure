variable "prefix" {}
variable "ssh_key" {}
variable "ssh_key_name" {}

resource "openstack_compute_keypair_v2" "public-key" {
  name       = var.ssh_key_name
  public_key = file(var.ssh_key)
}

variable "builder_image" {}
variable "builder_flavor" {}

resource "openstack_compute_instance_v2" "builder" {
  name        = "${var.prefix}-builder"
  image_name  = var.builder_image
  flavor_name = var.builder_flavor
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

resource "openstack_networking_floatingip_v2" "builder-ip" {
  pool        = "public"
  description = "${var.prefix}-builder-ip"
}

resource "openstack_compute_floatingip_associate_v2" "builder-ip" {
  floating_ip = openstack_networking_floatingip_v2.builder-ip.address
  instance_id = openstack_compute_instance_v2.builder.id
}

variable "infoblox_zone" {}
variable "infoblox_dns_view" {}

resource "infoblox_a_record" "builder-a-record" {
  dns_view = var.infoblox_dns_view
  fqdn     = "${var.prefix}-builder.${var.infoblox_zone}"
  ip_addr  = openstack_networking_floatingip_v2.builder-ip.address
}

