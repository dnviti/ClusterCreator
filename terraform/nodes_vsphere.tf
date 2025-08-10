# resource "vsphere_virtual_machine" "node" {
#   for_each = { for node in local.nodes : "${node.cluster_name}-${node.node_class}-${node.index}" => node }
#
#   name             = "${each.value.cluster_name}-${each.value.node_class}-${each.value.index}"
#   resource_pool_id = data.vsphere_resource_pool.pool.id
#   datastore_id     = data.vsphere_datastore.datastore.id
#
#   num_cpus = each.value.cores
#   memory   = each.value.memory
#
#   guest_id = "otherGuest"
#
#   network_interface {
#     network_id   = data.vsphere_network.network.id
#     adapter_type = "e1000"
#   }
#
#   disk {
#     label            = "disk0"
#     size             = 20
#     eagerly_scrub    = false
#     thin_provisioned = true
#   }
# }
