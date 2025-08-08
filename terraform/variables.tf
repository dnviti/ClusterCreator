locals {
    proxmox_host   = "192.168.254.1"
    proxmox_node   = "pve01"
    template_vm_id = 9000
    vsphere_server   = var.vsphere_server
    vsphere_user     = var.vsphere_user
    vsphere_password = var.vsphere_password
#     unifi_api_url  = "https://10.0.0.1/"
#     minio_endpoint = "https://s3.christensencloud.us"
#     minio_region   = "default"
#     minio_bucket   = "terraform-state"
}
