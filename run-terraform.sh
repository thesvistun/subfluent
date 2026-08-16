#!/usr/bin/env bash
set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

readonly TERRAFORM_DIR="${SCRIPT_DIR}/tools/terraform"

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_REGION=
export TF_VAR_user_ip=$(curl -s https://api.myip.com | jq -r .ip)

docker run -it --rm \
  -u $(id -u):$(id -g) \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_REGION \
  -e TF_VAR_user_ip \
  -v "${TERRAFORM_DIR}":"${TERRAFORM_DIR}" \
  -w "${TERRAFORM_DIR}" \
  hashicorp/terraform:1.15 "$@"