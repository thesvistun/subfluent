#!/usr/bin/env bash
set -e

readonly APP_VERSION="$(git describe --tags --no-abbrev)"

readonly RELEASE_NAME="stage"

helm install --set dockerTag="${APP_VERSION}" "${RELEASE_NAME}" tools/helm
