output "builder-ip-address" {
  value = openstack_networking_floatingip_v2.builder-ip.address
}

resource "local_file" "ansible_inventory" {
  filename        = "ansible/inventory/openstack.yml"
  file_permission = "0644"
  content = templatefile("terraform-inventory.tftpl", {
    private_key = trimsuffix(var.ssh_key, ".pub")
    builder_ip_address = openstack_networking_floatingip_v2.builder-ip.address
  })
}
