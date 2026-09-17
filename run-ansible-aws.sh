#!/usr/bin/env bash
set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

readonly ANSIBLE_DIR="${SCRIPT_DIR}/tools/ansible"

readonly TERRAFORM_DIR="${SCRIPT_DIR}/tools/terraform"

ansible-galaxy install -r "${ANSIBLE_DIR}/requirements.yaml"

## This inventory file builds Terraform
readonly INVENTORY="${TERRAFORM_DIR}/inventory.yaml"

ansible-playbook "${ANSIBLE_DIR}/docker.yaml" \
  --inventory "${INVENTORY}" \
  -u "ec2-user" \
  "$@"