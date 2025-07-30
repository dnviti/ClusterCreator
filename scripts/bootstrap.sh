#!/bin/bash

usage() {
  echo "Usage: ccr bootstrap [-y/--yes]"
  echo ""
  echo "Runs a series of Ansible playbooks to bootstrap your Kubernetes cluster with essential services."
  echo "Use -y or --yes to skip confirmation prompts."
  echo ""
  echo "The ansible playbooks handle:"
  echo " * Optional decoupled etcd cluster setup."
  echo " * Highly available control plane with Kube-VIP."
  echo " * Cilium CNI (with optional dual-stack networking)."
  echo " * Alternative container runtimes (gVisor, Kata)."
  echo " * Metrics server installation."
  echo " * Node labeling and tainting."
  echo " * Node preparation and joining."
}

ASSUME_YES=false

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -y|--yes) ASSUME_YES=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
    esac
    shift
done

# Cleanup
cleanup_files=(
  "../../tmp/${CLUSTER_NAME}/worker_join_command.sh"
  "../../tmp/${CLUSTER_NAME}/control_plane_join_command.sh"
)
set -e
trap 'echo "An error occurred. Cleaning up..."; cleanup_files "${cleanup_files[@]}"' ERR INT

echo -e "${GREEN}Preparing to bootstrap Kubernetes onto cluster: $CLUSTER_NAME.${ENDCOLOR}"

# --------------------------- Script Start ---------------------------

if [ "$ASSUME_YES" = false ]; then
  # Display what will be installed and ask for confirmation
  echo -e "${BLUE}The following core components will be installed to bootstrap the cluster:${ENDCOLOR}"
  echo "- Kubernetes Control Plane (kubeadm, kubelet, kubectl)"
  echo "- Decoupled etcd (if configured)"
  echo "- Kube-VIP for a highly available API server"
  echo "- Cilium CNI for networking"
  echo "- MetalLB for LoadBalancer services"
  echo "- An alternative container runtime (if configured in terraform/clusters.tf)"
  echo "- Metrics Server for resource monitoring"
  echo "- Kubelet Serving Cert Approver for TLS certificates"
  echo ""
  echo -e "${YELLOW}Warning: Once bootstrapped, you can't add/remove decoupled etcd nodes using this toolset.${ENDCOLOR}"
  read -r -p "Are you sure you want to proceed with bootstrapping? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 1
  fi
fi

echo -e "${GREEN}Bootstrapping cluster...${ENDCOLOR}"

playbooks=(
  "playbooks/setup-and-config/generate-hosts-txt.yaml"
  "playbooks/setup-and-config/trust-hosts.yaml"
  "playbooks/setup-and-config/prepare-nodes.yaml"
  "playbooks/system-services/etcd-nodes-setup.yaml"
  "playbooks/system-services/kubevip-setup.yaml"
)

# Check for container runtime and add the correct playbook for node-level installation
if grep -q 'runtime.*=.*"gvisor"' "$REPO_PATH/terraform/clusters.tf"; then
    playbooks+=("playbooks/system-services/gvisor-setup.yaml")
elif grep -q 'runtime.*=.*"kata"' "$REPO_PATH/terraform/clusters.tf"; then
    playbooks+=("playbooks/system-services/kata-setup.yaml")
fi

playbooks+=(
  "playbooks/cluster-management/controlplane-setup.yaml"
  "playbooks/setup-and-config/move-kubeconfig-local.yaml"
)

# Add the runtime class setup after the control plane is up
if grep -q 'runtime.*=.*"gvisor"' "$REPO_PATH/terraform/clusters.tf" || grep -q 'runtime.*=.*"kata"' "$REPO_PATH/terraform/clusters.tf"; then
    playbooks+=("playbooks/system-services/runtime-class-setup.yaml")
fi

playbooks+=(
  "playbooks/cluster-management/join-controlplane-nodes.yaml"
  "playbooks/cluster-management/join-worker-nodes.yaml"
  "playbooks/setup-and-config/move-kubeconfig-remote.yaml"
  "playbooks/cluster-management/conditionally-taint-controlplane.yaml"
  "playbooks/setup-and-config/etcd-encryption.yaml"
  "playbooks/system-services/kubelet-csr-approver.yaml"
  "playbooks/system-services/cilium-setup.yaml"
  "playbooks/system-services/metallb-setup.yaml"
  "playbooks/monitoring/metrics-server-setup.yaml"
  "playbooks/cluster-management/wait-for-pods.yaml"
  "playbooks/cluster-management/label-and-taint-nodes.yaml"
  "playbooks/cluster-management/wait-for-pods.yaml"
  "playbooks/setup-and-config/ending-output.yaml"
)

run_playbooks "${playbooks[@]}"

echo -e "${GREEN}Source your bash or zsh profile and run 'kubectx ${CLUSTER_NAME}' to access the cluster from your local machine.${ENDCOLOR}"

# ---------------------------- Script End ----------------------------

cleanup_files "${cleanup_files[@]}"

echo -e "${GREEN}DONE${ENDCOLOR}"
