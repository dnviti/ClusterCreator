# resource "nutanix_virtual_machine" "node" {
#   for_each = { for node in local.nodes : "${node.cluster_name}-${node.node_class}-${node.index}" => node }
#
#   name        = "${each.value.cluster_name}-${each.value.node_class}-${each.value.index}"
#   cluster_uuid = "00058a2b-6e5c-3a31-0000-00000000c824"
#
#   num_vcpus_per_socket = each.value.cores
#   num_sockets          = each.value.sockets
#   memory_size_mib      = each.value.memory
#
#   nic_list {
#     subnet_uuid = "00058a2b-6e5c-3a31-0000-00000000c824"
#   }
#
#   disk_list {
#     data_source_reference = {
#       kind = "image"
#       uuid = "00058a2b-6e5c-3a31-0000-00000000c824"
#     }
#     device_properties {
#       device_type = "DISK"
#     }
#   }
# }
