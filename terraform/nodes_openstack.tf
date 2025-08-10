# resource "openstack_compute_instance_v2" "node" {
#   for_each = { for node in local.nodes : "${node.cluster_name}-${node.node_class}-${node.index}" => node }
#
#   name              = "${each.value.cluster_name}-${each.value.node_class}-${each.value.index}"
#   image_id          = "ad091g56-947f-418b-bd42-5edb12345678"
#   flavor_id         = "3"
#   key_pair          = "my-key-pair"
#   security_groups   = ["default"]
#
#   network {
#     name = "my-network"
#   }
# }
