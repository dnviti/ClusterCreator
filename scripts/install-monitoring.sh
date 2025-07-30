#!/bin/bash

usage() {
  echo "Usage: ccr install-monitoring [-y/--yes]"
  echo ""
  echo "Installs the monitoring stack (Prometheus, Grafana, etc.) onto the cluster."
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
  echo -e "${BLUE}This will install the monitoring stack on cluster '${CLUSTER_NAME}'.${ENDCOLOR}"
  read -r -p "Are you sure you want to proceed? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 1
  fi
fi

echo -e "${GREEN}Installing monitoring stack on cluster: $CLUSTER_NAME...${ENDCOLOR}"

# --------------------------- Script Start ---------------------------

playbooks=(
  "playbooks/setup-and-config/generate-hosts-txt.yaml"
  "playbooks/setup-and-config/trust-hosts.yaml"
  "playbooks/monitoring/metrics-server-setup.yaml"
  "playbooks/monitoring/prometheus-setup.yaml"
)

run_playbooks "${playbooks[@]}"

# ---------------------------- Script End ----------------------------

echo -e "${GREEN}DONE${ENDCOLOR}"
