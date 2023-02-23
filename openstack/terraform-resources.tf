variable "prefix" {}
variable "ssh_key" {}

variable "builder_image" {}
variable "builder_flavor" {}

resource "openstack_compute_keypair_v2" "public-key" {
  name       = "${var.prefix}-key"
  public_key = file(var.ssh_key)
}

data "openstack_networking_network_v2" "external" {
  external = true
}

resource "openstack_compute_instance_v2" "builder" {
  name        = "${var.prefix}-builder"
  image_name  = var.builder_image
  flavor_name = var.builder_flavor
  key_pair    = openstack_compute_keypair_v2.public-key.name

  security_groups = ["cloudforms_ssh_in", "cloudforms_web_in"]
}

resource "openstack_networking_floatingip_v2" "builder-ip" {
  pool = data.openstack_networking_network_v2.external.name
  description = "${var.prefix}-builder-ip"
}

resource "openstack_compute_floatingip_associate_v2" "builder-ip" {
  floating_ip = openstack_networking_floatingip_v2.builder-ip.address
  instance_id = openstack_compute_instance_v2.builder.id
}
