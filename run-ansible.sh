#!/usr/bin/env bash
set -e

ansible-galaxy install -r tools/ansible/requirements.yaml

ansible-playbook tools/ansible/playbook.yaml "$@"