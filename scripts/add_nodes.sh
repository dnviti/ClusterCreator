#!/bin/bash

usage() {
  echo "Usage: ccr add-nodes"
  echo ""
  echo "Run a series of Ansible playbooks to add all existing un-joined nodes to the Kubernetes cluster"
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
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

echo -e "${GREEN}Adding nodes to cluster: $CLUSTER_NAME.${ENDCOLOR}"

# --------------------------- Script Start ---------------------------

playbooks=(
  "playbooks/setup-and-config/generate-hosts-txt.yaml"
  "playbooks/setup-and-config/trust-hosts.yaml"
  "playbooks/setup-and-config/prepare-nodes.yaml"
  "playbooks/system-services/kubevip-setup.yaml"
  "playbooks/cluster-management/get-join-commands.yaml"
  "playbooks/cluster-management/join-controlplane-nodes.yaml"
  "playbooks/cluster-management/join-worker-nodes.yaml"
  "playbooks/setup-and-config/move-kubeconfig-remote.yaml"
  "playbooks/cluster-management/conditionally-taint-controlplane.yaml"
  "playbooks/setup-and-config/etcd-encryption.yaml"
  "playbooks/cluster-management/label-and-taint-nodes.yaml"
  "playbooks/setup-and-config/ending-output.yaml"
)
run_playbooks "${playbooks[@]}"

# ---------------------------- Script End ----------------------------

cleanup_files "${cleanup_files[@]}"

echo -e "${GREEN}DONE${ENDCOLOR}"
