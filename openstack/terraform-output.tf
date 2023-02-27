resource "local_file" "ansible_inventory" {
  filename        = "ansible/inventory/hosts.yml"
  content = templatefile("ansible/inventory/hosts.tftpl", {
    private_key = trimsuffix(var.ssh_key, ".pub")
    build_controller_ip_address = openstack_networking_floatingip_v2.build-controller-ip.address
    build_nodes = tomap({
      for i in range(var.build_node_count):
      "${local.build_nodes[i]}" => element(openstack_networking_floatingip_v2.build-node-ip.*.address, i)
    })
  })
}

resource "local_file" "infoblox_list" {
  filename        = "infoblox/test/list.json"
  content = templatefile("infoblox/test/list.tftpl", {
    build_controller_hostname = "${var.prefix}-build-controller.${var.infoblox_zone}"
    build_node_hostnames = [for i in range(var.build_node_count): "${var.prefix}-${local.build_nodes[i]}.${var.infoblox_zone}"]
  })
}

