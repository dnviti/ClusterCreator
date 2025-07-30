#!/bin/bash

usage() {
  echo "Usage: ccr must-gather"
  echo ""
  echo "Gathers logs and diagnostic information from the cluster and packages it into a tarball."
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
    esac
    shift
done

# Set up a directory for the logs using an absolute path
LOG_DIR="$(pwd)/must-gather-$(date +%Y%m%d%H%M%S)"
mkdir -p "$LOG_DIR"

echo -e "${GREEN}Gathering diagnostic information into directory: $LOG_DIR${ENDCOLOR}"

# --------------------------- Script Start ---------------------------

playbooks=(
  "playbooks/cluster-management/must-gather.yaml"
)
# Pass the absolute path of the log directory to the playbook
run_playbooks "-e log_dir=$LOG_DIR" "${playbooks[@]}"

# ---------------------------- Script End ----------------------------

echo -e "${GREEN}Compressing logs...${ENDCOLOR}"
tar -czf "$LOG_DIR.tar.gz" "$LOG_DIR"
rm -rf "$LOG_DIR"

echo -e "${GREEN}DONE. Logs are available in $LOG_DIR.tar.gz${ENDCOLOR}"
