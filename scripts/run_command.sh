#!/bin/bash

usage() {
    echo "Usage: ccr run-command 'command_to_run' [<hostname_or_node_class>] [-y/--yes]"
    echo ""
    echo "Runs a command with elevated permissions on the host or node class specified."
    echo "The default node class is 'all'."
    echo "Use -y or --yes to skip confirmation prompts."
}

GROUP_NAME="all"
COMMAND=""
ASSUME_YES=false
PLAYBOOK_FILE="/tmp/ansible_playbook_run_command.yml"

# Parse command-line arguments
POSITIONAL_ARGS=()
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -y|--yes)
            ASSUME_YES=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift
            ;;
    esac
done

# Restore positional arguments
set -- "${POSITIONAL_ARGS[@]}"

# Assign positional arguments
if [[ -n "$1" ]]; then
    COMMAND="$1"
fi
if [[ -n "$2" ]]; then
    GROUP_NAME="$2"
fi


# Required variables check
required_vars=(
  "COMMAND"
)
check_required_vars "${required_vars[@]}"

# Print variables for confirmation if not in headless mode
if [ "$ASSUME_YES" = false ]; then
    print_env_vars "GROUP_NAME" "COMMAND"
fi

# Cleanup
cleanup_files=(
  "$PLAYBOOK_FILE"
)
set -e
trap 'echo "An error occurred. Cleaning up..."; cleanup_files "${cleanup_files[@]}"' ERR INT

if [ "$ASSUME_YES" = false ]; then
    read -r -p "Are you sure you want to run this command? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Operation canceled."
        exit 1
    fi
fi

echo -e "${GREEN}Running '$COMMAND' on group '$GROUP_NAME' from cluster: $CLUSTER_NAME.${ENDCOLOR}"

# --------------------------- Script Start ---------------------------

# Create a temporary Ansible playbook
cat << EOF > "$PLAYBOOK_FILE"
---
- name: Execute command on specified hosts
  hosts: $GROUP_NAME
  gather_facts: false
  become: true
  tasks:
    - name: Execute the command
      command: $COMMAND
      register: cmd_output
    - name: Print command output (skips when command has no output)
      debug:
        msg: "{{ cmd_output.stdout_lines }}"
      when: cmd_output.stdout_lines | length > 0
EOF

playbooks=(
  "playbooks/setup-and-config/generate-hosts-txt.yaml"
  "playbooks/setup-and-config/trust-hosts.yaml"
  "$PLAYBOOK_FILE"
)
run_playbooks "${playbooks[@]}"

# ---------------------------- Script End ----------------------------

cleanup_files "${cleanup_files[@]}"

echo -e "${GREEN}DONE${ENDCOLOR}"
