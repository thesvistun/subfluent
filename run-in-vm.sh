#!/usr/bin/env bash
set -e

fail() {
  echo "$1" >&2
  exit 1
}

help() {
  echo "Usage: $0 [--playbook] [--help]"
  echo "--playbook  Ansible playbook filename to provision infrastracture."
  echo "--help Output this help"
  exit 0
}

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

readonly VAGRANT_DIR="${SCRIPT_DIR}/tools/vagrant"

while [[ $# -gt 0 ]]; do
  case $1 in
    --playbook)
      export PLAYBOOK=$2
      shift
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

cd "${VAGRANT_DIR}"

vagrant up
