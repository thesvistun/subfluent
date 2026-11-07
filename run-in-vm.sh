#!/usr/bin/env bash
set -e

fail() {
  echo "$1" >&2
  exit 1
}

help() {
  echo "Usage: $0 --tls-hostname <example.host.name> [--playbook] [--help]"
  echo "--tls-hostname  hostname which the TLS certificate was issued to."
  echo "--playbook      Ansible playbook filename to provision infrastracture. Default: docker.yaml."
  echo "--install-deps  Install dependencies: Ansible and Python modules."
  echo "--help          Output this help"
  exit 0
}

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

readonly ANSIBLE_DIR="${SCRIPT_DIR}/tools/ansible"

readonly VAGRANT_DIR="${SCRIPT_DIR}/tools/vagrant"

install_deps=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --tls-hostname)
      export TLS_HOSTNAME=$2
      shift
      shift
      ;;
    --playbook)
      export PLAYBOOK=$2
      shift
      shift
      ;;
    --install-deps)
      install_deps=1
      shift
      ;;
    --help)
      help
      ;;
    --*)
      fail "Unknown option $1"
      ;;
    *)
      shift
      ;;
  esac
done

[[ "$PLAYBOOK" == 'k3s.yaml' && -z "$TLS_HOSTNAME" ]] && \
  fail 'TLS hostname must be set. See help for more information.'

## Installing deps
if (( $install_deps )); then
  ansible-galaxy install -r "${ANSIBLE_DIR}/requirements.yaml"
  pip install -r "${ANSIBLE_DIR}/requirements.txt"
fi

cd "${VAGRANT_DIR}"

vagrant up
