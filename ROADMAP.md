# **ClusterCreator Roadmap**

This document outlines the planned features for the ClusterCreator project, along with concise prompts for AI-driven implementation.

### **Core Enhancements**

* **Improve VM Template Creation ScriptAI Prompt:** "Update the scripts/k8s\_vm\_template/create\_template\_helper.sh script. Add a network connectivity pre-flight check before installing packages. After installation, add a verification step to confirm that kubectl, kubeadm, and containerd are present and executable."  
* **Add Retry Logic to vmctl SnapshotsAI Prompt:** "Modify the scripts/vmctl.sh script. In the perform\_action\_with\_retry function, add specific retry logic for the snapshot action to handle intermittent Proxmox API errors."  
* **Refactor etcd Setup to Remove SSH DependencyAI Prompt:** "Review the ansible/etcd-nodes-setup.yaml playbook. Modify the certificate distribution logic to orchestrate all actions from the Ansible control node, removing the need for direct SSH between etcd nodes."

### **Addon Integrations**

* **Add Monitoring Stack (kube-prometheus-stack)AI Prompt:** "Create a new Ansible playbook ansible/prometheus-setup.yaml to deploy the kube-prometheus-stack Helm chart. Update install-addons.sh to detect a new monitoring\_enabled flag in terraform/clusters.tf and run the new playbook."  
* **Add Logging Stack (Loki/Promtail)AI Prompt:** "Create a new Ansible playbook ansible/loki-setup.yaml to deploy the Loki and Promtail Helm charts. Update install-addons.sh to detect a new logging\_enabled flag in terraform/clusters.tf and run the new playbook."  
* **Add Automated DNS (ExternalDNS)AI Prompt:** "Create a new Ansible playbook ansible/externaldns-setup.yaml to deploy the ExternalDNS Helm chart. Update install-addons.sh to detect a new external\_dns\_enabled flag in terraform/clusters.tf."  
* **Integrate Encrypted Secrets (SOPS)AI Prompt:** "Integrate SOPS into the project. Update scripts/configure\_secrets.sh to use sops for encrypting and decrypting secrets files, and document the new workflow."  
* **Finalize Git Platform and Security AddonsAI Prompt:** "Review and test the Ansible playbooks for Gitea, GitLab, GitHub runners, Falco, and Sysdig. Ensure their installation is idempotent and fully functional, and document any required user configuration."