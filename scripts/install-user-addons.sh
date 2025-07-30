#!/bin/bash

usage() {
  echo "Usage: ccr install-user-addons [-y/--yes]"
  echo ""
  echo "Installs all configured user addons onto the cluster based on the settings in terraform/clusters.tf."
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

echo -e "${GREEN}Checking for configured user addons on cluster: $CLUSTER_NAME...${ENDCOLOR}"

# --------------------------- Script Start ---------------------------

addons_to_install=()
playbooks=()

# --- User Addons ---
if grep -q 'provider.*=.*"gitea"' "$REPO_PATH/terraform/clusters.tf"; then
    addons_to_install+=("Gitea (Git Platform)")
    playbooks+=("playbooks/addons/gitea-setup.yaml")
    if grep -q 'runners_enabled.*=.*true' "$REPO_PATH/terraform/clusters.tf"; then
        addons_to_install+=("Gitea Runners")
        playbooks+=("playbooks/addons/gitea-runner-setup.yaml")
    fi
fi
if grep -q 'provider.*=.*"gitlab"' "$REPO_PATH/terraform/clusters.tf"; then
    addons_to_install+=("GitLab (Git Platform)")
    playbooks+=("playbooks/addons/gitlab-setup.yaml")
    if grep -q 'runners_enabled.*=.*true' "$REPO_PATH/terraform/clusters.tf"; then
        addons_to_install+=("GitLab Runners")
        playbooks+=("playbooks/addons/gitlab-runner-setup.yaml")
    fi
fi
if grep -q 'provider.*=.*"github"' "$REPO_PATH/terraform/clusters.tf"; then
    if grep -q 'runners_enabled.*=.*true' "$REPO_PATH/terraform/clusters.tf"; then
        addons_to_install+=("GitHub Runners")
        playbooks+=("playbooks/addons/github-runner-setup.yaml")
    fi
fi
if grep -q 'argocd_enabled.*=.*true' "$REPO_PATH/terraform/clusters.tf"; then
    addons_to_install+=("ArgoCD (GitOps)")
    playbooks+=("playbooks/addons/argocd-setup.yaml")
fi

if [ ${#addons_to_install[@]} -eq 0 ]; then
    echo -e "${YELLOW}No user addons are configured for installation in terraform/clusters.tf. Exiting.${ENDCOLOR}"
    exit 0
fi

if [ "$ASSUME_YES" = false ]; then
  echo -e "${BLUE}The following user addons will be installed on cluster '${CLUSTER_NAME}':${ENDCOLOR}"
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

echo -e "${GREEN}Installing user addons...${ENDCOLOR}"

# Always run generate-hosts-txt.yaml and trust-hosts.yaml first
run_playbooks "playbooks/setup-and-config/generate-hosts-txt.yaml" "playbooks/setup-and-config/trust-hosts.yaml" "${playbooks[@]}"

# ---------------------------- Script End ----------------------------

echo -e "${GREEN}DONE${ENDCOLOR}"
