variable "vm_username" {
  default = "kube" # change me to your username
}
variable "vm_password" {
  default = "default_vm_password"
}
variable "vm_ssh_key" {
  type = list(string)
  default = [
    "ssh-rsa AAAAA..."
  ]
}
variable "proxmox_username" {
  default = "terraform"
}
variable "proxmox_api_token" {
  default = "terraform@pve!provider=TOKEN"
}

variable "vsphere_server" {
  description = "The vCenter server address."
  type        = string
  default     = "your-vsphere-server"
}

variable "vsphere_user" {
  description = "The vCenter username."
  type        = string
  default     = "your-vsphere-user"
}

variable "vsphere_password" {
  description = "The vCenter password."
  type        = string
  sensitive   = true
  default     = "your-vsphere-password"
}

variable "openstack_user_name" {
  description = "The username for OpenStack."
  type        = string
  default     = "admin"
}

variable "openstack_tenant_name" {
  description = "The tenant name for OpenStack."
  type        = string
  default     = "admin"
}

variable "openstack_password" {
  description = "The password for OpenStack."
  type        = string
  sensitive   = true
  default     = "password"
}

variable "openstack_auth_url" {
  description = "The authentication URL for OpenStack."
  type        = string
  default     = "http://your-openstack-auth-url:5000/v3"
}

variable "openstack_region" {
  description = "The region to use for OpenStack."
  type        = string
  default     = "RegionOne"
}
