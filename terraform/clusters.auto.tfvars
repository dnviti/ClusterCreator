clusters = { # create your clusters here using the above object
    "alpha" = {
      cluster_name             = "alpha"
      cluster_id               = 1
      storage_provisioner      = "local-path"
      storage_disk             = "/dev/vda"
      kubeconfig_file_name     = "alpha.yml"
      start_on_proxmox_boot    = true
      ingress_controller       = "nginx"
      reboot_after_update      = true
      runtime                  = "gvisor"
      cert_manager_enabled     = true
      apps_domain              = "apps.alpha.kube.arpa.local"
      monitoring = {
        enabled                = true
      }
      security = {
        falco_enabled          = false
      }
      gitops = {
        argocd_enabled         = true
      }
      git_platform = {
        provider               = "gitea"
        runners_enabled        = true
      }
      ssh = {
        ssh_user               = "kube"
      }
      networking = {
        ipv4 = {
          subnet_prefix        = "10.0.1"
          subnet_mask          = 24
          gateway              = "10.0.1.1"
          dns1                 = "10.0.1.1"
          dns2                 = "10.0.1.2"
          management_cidrs     = "10.0.0.0/30,10.0.60.2,10.0.50.5,10.0.50.6"
          lb_cidrs             = "10.0.1.200/29,10.0.1.208/28,10.0.1.224/28,10.0.1.240/29,10.0.1.248/30,10.0.1.252/31"
        }
        ipv6 = {}
        kube_vip = {
          vip                  = "10.0.1.100"
          vip_hostname         = "api.alpha.kube.arpa.local"
        }
      }
      node_classes = {
        controlplane = {
          cpu_type             = "host"
          count                = 1
          sockets              = 1
          cores                = 16
          memory               = 16384
          pve_nodes            = [ "pve" ]
          disks      = [
            { datastore = "local-lvm", size = 200 }
          ]
          start_ip   = 110
          labels = [
            "nodeclass=controlplane"
          ]
        }
      }
    }
    "beta" = {
      cluster_name             = "beta"
      cluster_id               = 2
      storage_provisioner      = "longhorn"
      storage_disk             = "/dev/vdb"
      kubeconfig_file_name     = "beta.yml"
      start_on_proxmox_boot    = true
      ingress_controller       = "nginx"
      reboot_after_update      = true
      runtime                  = "gvisor"
      cert_manager_enabled     = true
      apps_domain              = "apps.beta.kube.arpa.local"
      monitoring = {
        enabled = true
      }
      security = {
        falco_enabled          = false
      }
      gitops = {
        argocd_enabled         = true
      }
      git_platform = {
        provider               = "gitea"
        runners_enabled        = true
      }
      ssh = {
        ssh_user               = "kube"
      }
      networking = {
        ipv4 = {
          subnet_prefix        = "10.0.2"
          subnet_mask          = 24
          gateway              = "10.0.2.1"
          dns1                 = "10.0.2.1"
          dns2                 = "10.0.2.2"
          management_cidrs     = "10.0.0.0/30,10.0.60.2,10.0.50.5,10.0.50.6"
          lb_cidrs             = "10.0.2.200/29,10.0.2.208/28,10.0.2.224/28,10.0.2.240/29,10.0.2.248/30,10.0.2.252/31"
        }
        ipv6 = {}
        kube_vip = {
          vip                  = "10.0.2.100"
          vip_hostname         = "api.beta.kube.arpa.local"
        }
      }
      node_classes = {
        controlplane = {
          count      = 1
          cores      = 4
          memory     = 4096
          disks      = [
            { datastore = "local-lvm", size = 20 }
          ]
          start_ip   = 110
          labels = [
            "nodeclass=controlplane"
          ]
        }
        general = {
          count      = 2
          cores      = 8
          memory     = 4096
          disks      = [
            { datastore = "local-lvm", size = 20 },
            { datastore = "local-lvm", size = 200 }
          ]
          start_ip   = 130
          labels = [
            "nodeclass=general"
          ]
        }
      }
    }
    "gamma" = {
      cluster_name             = "gamma"
      cluster_id               = 3
      kubeconfig_file_name     = "gamma.yml"
      start_on_proxmox_boot    = true
      ingress_controller       = "nginx"
      reboot_after_update      = true
      runtime                  = "gvisor"
      cert_manager_enabled     = true
      apps_domain              = "apps.gamma.kube.arpa.local"
      monitoring = {
        enabled = true
      }
      security = {
        falco_enabled          = false
      }
      gitops = {
        argocd_enabled         = true
      }
      git_platform = {
        provider               = "gitea"
        runners_enabled        = true
      }
      ssh = {
        ssh_user               = "kube"
      }
      networking = {
        ipv4 = {
          subnet_prefix        = "10.0.3"
          subnet_mask          = 24
          gateway              = "10.0.3.1"
          dns1                 = "10.0.3.1"
          dns2                 = "10.0.3.2"
          management_cidrs     = "10.0.0.0/30,10.0.60.2,10.0.50.5,10.0.50.6"
          lb_cidrs             = "10.0.3.200/29,10.0.3.208/28,10.0.3.224/28,10.0.3.240/29,10.0.3.248/30,10.0.3.252/31"
        }
        ipv6 = {}
        kube_vip = {
          vip                  = "10.0.3.100"
          vip_hostname         = "api.gamma.kube.arpa.local"
        }
      }
      node_classes = {
        controlplane = {
          count     = 3
          cores     = 4
          memory    = 4096
          disks     = [
            { datastore = "local-lvm", size = 20 }
          ]
          start_ip = 110
          labels   = [
            "nodeclass=controlplane"
          ]
        }
        etcd = {
          count     = 3
          disks     = [
            { datastore = "local-lvm", size = 20 }
          ]
          start_ip = 120
        }
        general = {
          count     = 3
          cores     = 8
          memory    = 4096
          disks     = [
            { datastore = "local-lvm", size = 20 }
          ]
          start_ip = 130
          labels   = [
            "nodeclass=general"
          ]
        }
        gpu = {
          count      = 2
          pve_nodes  = [ "Acropolis", "Parthenon" ]
          cpu_type   = "host"
          disks      = [
            { datastore = "local-lvm", size = 20 },
            { datastore = "local-lvm", size = 200 }
          ]
          start_ip   = 190
          labels = [
            "nodeclass=gpu"
          ]
          taints  = [
            "gpu=true:NoSchedule"
          ]
          devices = [
            { mapping = "my-full-gpu-passthrough" }
          ]
        }
      }
    }
  }