#!/bin/bash

usage() {
  echo "Usage: ccr install-security [-y/--yes]"
  echo ""
  echo "Installs all configured security addons onto the cluster based on the settings in terraform/clusters.tf."
  echo "Use -y or --yes to skip confirmation prompts."
  echo ""
  echo "This script will automatically detect and install addons for:"
  echo "  - Falco"
  echo "  - Sysdig"
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

echo -e "${GREEN}Checking for configured security addons on cluster: $CLUSTER_NAME...${ENDCOLOR}"

# --------------------------- Script Start ---------------------------

addons_to_install=()
playbooks=()

# --- Security ---
if grep -q 'falco_enabled.*=.*true' "$REPO_PATH/terraform/clusters.tf"; then
    if grep -q 'runtime.*=.*"gvisor"' "$REPO_PATH/terraform/clusters.tf"; then
        addons_to_install+=("Falco with gVisor integration (Security)")
        playbooks+=("playbooks/addons/falco-gvisor-integration.yaml")
    else
        addons_to_install+=("Falco (Security)")
        playbooks+=("falco-setup.yaml")
    fi
fi
if grep -q 'sysdig_enabled.*=.*true' "$REPO_PATH/terraform/clusters.tf"; then
    addons_to_install+=("Sysdig (Security)")
    playbooks+=("playbooks/addons/sysdig-setup.yaml")
fi

if [ ${#addons_to_install[@]} -eq 0 ]; then
    echo -e "${YELLOW}No security addons are configured for installation in terraform/clusters.tf. Exiting.${ENDCOLOR}"
    exit 0
fi

if [ "$ASSUME_YES" = false ]; then
  echo -e "${BLUE}The following security addons will be installed on cluster '${CLUSTER_NAME}':${ENDCOLOR}"
  for addon in "${addons_to_install[@]}"; do
      echo "- $addon"
  done
  echo ""

  read -r -p "Are you sure you want to proceed with installing these addons? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 1
  fi
fi

echo -e "${GREEN}Installing security addons...${ENDCOLOR}"

# Always run generate-hosts-txt.yaml and trust-hosts.yaml first
run_playbooks "playbooks/setup-and-config/generate-hosts-txt.yaml" "playbooks/setup-and-config/trust-hosts.yaml" "${playbooks[@]}"

# ---------------------------- Script End ----------------------------

echo -e "${GREEN}DONE${ENDCOLOR}"
