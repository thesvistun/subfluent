#!/usr/bin/env bash
set -e

readonly APP_VERSION="$(git describe --tags --no-abbrev)"

readonly RELEASE_NAME="subfluent"

readonly NAMESPACE="subfluent"

fail() {
  echo "$1" >&2
  exit 1
}

help() {
  echo "Usage: $0 --tls-hostname <example.host.name> [--help]"
  echo "--tls-hostname  hostname which the TLS certificate was issued to."
  echo "--help          Output this help"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --tls-hostname)
      tls_hostname=$2
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

[[ -z "$tls_hostname" ]] && \
  fail 'TLS hostname must be set. See help for more information.'

helm upgrade --install \
  --namespace "${NAMESPACE}" --create-namespace \
  --set dockerTag="${APP_VERSION}" \
  --set tls.hostname="$tls_hostname" \
  "${RELEASE_NAME}" \
  tools/helm
