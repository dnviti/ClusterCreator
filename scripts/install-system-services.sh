#!/bin/bash

usage() {
  echo "Usage: ccr install-system-services [-y/--yes]"
  echo ""
  echo "Installs all configured system services onto the cluster based on the settings in terraform/clusters.tf."
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

echo -e "${GREEN}Checking for configured system services on cluster: $CLUSTER_NAME...${ENDCOLOR}"

# --------------------------- Script Start ---------------------------

# Base services
addons_to_install=()
# Order is important: CNI first, then CoreDNS.
playbooks=()

if grep -q 'ingress_controller.*=.*"nginx"' "$REPO_PATH/terraform/clusters.tf"; then
    addons_to_install+=("NGINX Ingress Controller")
    playbooks+=("playbooks/system-services/nginx-ingress-setup.yaml")
fi
if grep -q 'ingress_controller.*=.*"traefik"' "$REPO_PATH/terraform/clusters.tf"; then
    addons_to_install+=("Traefik Ingress Controller")
    playbooks+=("playbooks/system-services/traefik-setup.yaml")
fi
if grep -q 'cert_manager_enabled.*=.*true' "$REPO_PATH/terraform/clusters.tf"; then
    addons_to_install+=("cert-manager (TLS Certificates)")
    playbooks+=("playbooks/system-services/cert-manager-setup.yaml")
    playbooks+=("playbooks/system-services/cert-manager-issuers.yaml")
fi
if grep -q 'storage_provisioner.*=.*"longhorn"' "$REPO_PATH/terraform/clusters.tf"; then
    addons_to_install+=("Longhorn (Storage)")
    playbooks+=("playbooks/system-services/longhorn-setup.yaml")
fi
if grep -q 'storage_provisioner.*=.*"ceph"' "$REPO_PATH/terraform/clusters.tf"; then
    addons_to_install+=("Ceph (Storage)")
    playbooks+=("playbooks/system-services/ceph-setup.yaml")
fi
if grep -q 'storage_provisioner.*=.*"local-path"' "$REPO_PATH/terraform/clusters.tf"; then
    addons_to_install+=("Local Path Provisioner (Storage)")
    playbooks+=("playbooks/system-services/local-storageclasses-setup.yaml")
fi

if [ "$ASSUME_YES" = false ]; then
  echo -e "${BLUE}The following system services will be installed on cluster '${CLUSTER_NAME}':${ENDCOLOR}"
  for addon in "${addons_to_install[@]}"; do
      echo "- $addon"
  done
  echo ""

  read -r -p "Are you sure you want to proceed with installing these services? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 1
  fi
fi

echo -e "${GREEN}Installing system services...${ENDCOLOR}"

# Always run generate-hosts-txt.yaml and trust-hosts.yaml first
run_playbooks "playbooks/setup-and-config/generate-hosts-txt.yaml" "playbooks/setup-and-config/trust-hosts.yaml" "${playbooks[@]}"

# ---------------------------- Script End ----------------------------

echo -e "${GREEN}DONE${ENDCOLOR}"
