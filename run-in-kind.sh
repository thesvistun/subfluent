#!/usr/bin/env bash
set -e

readonly APP_VERSION="$(git describe --tags --no-abbrev)"

readonly RELEASE_NAME="subfluent"

readonly NAMESPACE="subfluent"

helm upgrade --install \
  --namespace "${NAMESPACE}" --create-namespace \
  --set dockerTag="${APP_VERSION}" \
  "${RELEASE_NAME}" \
  tools/helm
