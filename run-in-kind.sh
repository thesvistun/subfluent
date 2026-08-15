#!/usr/bin/env bash
set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

readonly APP_VERSION="$(git describe --tags)"

readonly DOCKER_REGISTRY='localhost:5001'

readonly IMAGE_NAME="${DOCKER_REGISTRY}/subfluent"

readonly RELEASE_NAME="stage"

## App directory inside a container.
readonly CONTAINER_APP_DIR='/usr/local/share/subfluent'

## App directory inside a container.
readonly CONTAINER_APP_DATA_DIR="${CONTAINER_APP_DIR}/data"

## Building Docker image with the app inside.
docker build \
  --build-arg VERSION="${APP_VERSION}" \
  --build-arg APP_DIR="${CONTAINER_APP_DIR}" \
  -t "${IMAGE_NAME}:${APP_VERSION}" \
  -f "${SCRIPT_DIR}/tools/docker/Dockerfile" \
  "${SCRIPT_DIR}"

## Pusing Docker image to the Docker registry.
docker push "${IMAGE_NAME}:${APP_VERSION}"

yq ".appVersion = \"${APP_VERSION}\"" -i tools/helm/Chart.yaml

helm install --set dataPath="${CONTAINER_APP_DATA_DIR}" "${RELEASE_NAME}" tools/helm
