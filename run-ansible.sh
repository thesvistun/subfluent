#!/usr/bin/env bash
set -e

AWS_REGION=''

ansible-galaxy install -r tools/ansible/requirements.yaml

ansible-playbook tools/ansible/playbook.yaml --extra-vars "aws_region=${AWS_REGION}" "$@"