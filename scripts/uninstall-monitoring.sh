#!/bin/bash

usage() {
  echo "Usage: ccr uninstall-monitoring [-y/--yes]"
  echo ""
  echo "Uninstalls the configured monitoring stack from the cluster."
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

if [ "$ASSUME_YES" = false ]; then
  echo -e "${YELLOW}WARNING: This will uninstall the monitoring stack from the cluster '${CLUSTER_NAME}'.${ENDCOLOR}"
  read -r -p "Are you sure you want to proceed? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 1
  fi
fi

echo -e "${GREEN}Uninstalling monitoring stack from cluster: $CLUSTER_NAME.${ENDCOLOR}"

# --------------------------- Script Start ---------------------------

playbooks=(
  "playbooks/uninstall/uninstall-monitoring.yaml"
)

run_playbooks "${playbooks[@]}"

# ---------------------------- Script End ----------------------------

echo -e "${GREEN}DONE${ENDCOLOR}"
