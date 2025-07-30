#!/bin/bash

usage() {
  echo "Usage: ccr reset-all-nodes [-y/--yes]"
  echo ""
  echo "Removes all addons and Kubernetes files, services, and configurations from all nodes. This is a complete cluster teardown."
  echo "Use -y or --yes to skip confirmation prompts."
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

echo -e "${GREEN}Completely resetting cluster: $CLUSTER_NAME.${ENDCOLOR}"

# --------------------------- Script Start ---------------------------

if [ "$ASSUME_YES" = false ]; then
  # Prompt for confirmation
  echo -e "${YELLOW}Warning: This will destroy your current cluster and all its applications.${ENDCOLOR}"
  read -r -p "Are you sure you want to proceed? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 1
  fi
fi

# Step 1: Uninstall all addons from the cluster
echo -e "${BLUE}Step 1: Uninstalling all addons...${ENDCOLOR}"
"$REPO_PATH/scripts/uninstall-addons.sh" --yes

# Step 2: Uninstall the monitoring stack
echo -e "${BLUE}Step 2: Uninstalling the monitoring stack...${ENDCOLOR}"
"$REPO_PATH/scripts/uninstall-monitoring.sh" --yes

# Step 3: Reset the Kubernetes nodes
echo -e "${BLUE}Step 3: Resetting all Kubernetes nodes...${ENDCOLOR}"
playbooks=(
  "playbooks/setup-and-config/generate-hosts-txt.yaml"
  "playbooks/setup-and-config/trust-hosts.yaml"
  "playbooks/cluster-management/reset-nodes.yaml"
)
run_playbooks "${playbooks[@]}"

# ---------------------------- Script End ----------------------------

cleanup_files "${cleanup_files[@]}"

echo -e "${GREEN}DONE${ENDCOLOR}"
