#!/bin/bash

usage() {
  echo "Usage: ccr select-provider"
  echo ""
  echo "Selects the main provider for your cluster."
  echo ""
  echo "Providers that can be selected:"
  echo "  * proxmox"
  echo "  * vsphere"
  echo "  * nutanix"
  echo "  * openstack"
}

# General function to toggle a block in a Terraform file using awk for balanced braces
toggle_tf_block() {
    local start_pattern="$1"
    local condition="$2"
    local file="$3"

    if [[ "$condition" == "y" ]]; then
        # Uncomment block: remove leading '# ' from each line within the block
        awk -v pat="$start_pattern" '
            BEGIN { inside = 0; brace_count = 0 }
            $0 ~ "^# *" pat { inside = 1 }
            inside {
                sub(/^# /, "", $0)
                if ($0 ~ /{/) brace_count++
                if ($0 ~ /}/) brace_count--
                if (brace_count == 0) inside = 0
            }
            { print }
        ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    else
        # Comment block: add '# ' at the start of each line within the block
        awk -v pat="$start_pattern" '
            BEGIN { inside = 0; brace_count = 0 }
            $0 ~ pat { inside = 1 }
            inside {
                if ($0 !~ /^#/) $0 = "# " $0
                if ($0 ~ /{/) brace_count++
                if ($0 ~ /}/) brace_count--
                if (brace_count == 0) inside = 0
            }
            { print }
        ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
}

# Prompt the user
echo -e "${YELLOW}Which provider do you want to use? (proxmox/vsphere/nutanix/openstack)${ENDCOLOR}"
read -r provider

# Define file path variables
providers_file="$REPO_PATH/terraform/providers.tf"
locals_file="$REPO_PATH/terraform/locals.tf"
proxmox_nodes_file="$REPO_PATH/terraform/nodes_proxmox.tf"
vsphere_nodes_file="$REPO_PATH/terraform/nodes_vsphere.tf"
nutanix_nodes_file="$REPO_PATH/terraform/nodes_nutanix.tf"
openstack_nodes_file="$REPO_PATH/terraform/nodes_openstack.tf"

# Update locals.tf
sed -i "s/provider = \".*\"/provider = \"$provider\"/" "$locals_file"

# Toggle providers
toggle_tf_block "proxmox =" "$([ "$provider" == "proxmox" ] && echo y || echo n)" "$providers_file"
toggle_tf_block 'provider "proxmox"' "$([ "$provider" == "proxmox" ] && echo y || echo n)" "$providers_file"
toggle_tf_block 'resource "proxmox_virtual_environment_vm"' "$([ "$provider" == "proxmox" ] && echo y || echo n)" "$proxmox_nodes_file"

toggle_tf_block "vsphere =" "$([ "$provider" == "vsphere" ] && echo y || echo n)" "$providers_file"
toggle_tf_block 'provider "vsphere"' "$([ "$provider" == "vsphere" ] && echo y || echo n)" "$providers_file"
toggle_tf_block 'resource "vsphere_virtual_machine"' "$([ "$provider" == "vsphere" ] && echo y || echo n)" "$vsphere_nodes_file"

toggle_tf_block "nutanix =" "$([ "$provider" == "nutanix" ] && echo y || echo n)" "$providers_file"
toggle_tf_block 'provider "nutanix"' "$([ "$provider" == "nutanix" ] && echo y || echo n)" "$providers_file"
toggle_tf_block 'resource "nutanix_virtual_machine"' "$([ "$provider" == "nutanix" ] && echo y || echo n)" "$nutanix_nodes_file"

toggle_tf_block "openstack =" "$([ "$provider" == "openstack" ] && echo y || echo n)" "$providers_file"
toggle_tf_block 'provider "openstack"' "$([ "$provider" == "openstack" ] && echo y || echo n)" "$providers_file"
toggle_tf_block 'resource "openstack_compute_instance_v2"' "$([ "$provider" == "openstack" ] && echo y || echo n)" "$openstack_nodes_file"

echo -e "${GREEN}Configuration has been updated based on your selections.${ENDCOLOR}"

echo ""
echo -e "${GREEN}Running tofu init to initialize new providers${ENDCOLOR}"
"${REPO_PATH}/clustercreator.sh" tofu init -upgrade -reconfigure

echo -e "${GREEN}DONE${ENDCOLOR}"
