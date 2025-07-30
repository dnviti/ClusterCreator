#!/bin/bash
# This script simply calls kubectl to get nodes in JSON format.
# It is executed by the main 'ccr' script, which ensures all environment
# checks and variables are loaded correctly first.
check_required_commands "kubectl"
kubectl get nodes -o json
