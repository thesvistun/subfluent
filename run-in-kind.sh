#!/usr/bin/env bash
set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

readonly DOCKER_REGISTRY='localhost:5001'

readonly IMAGE_NAME="${DOCKER_REGISTRY}/subfluent:latest"

readonly RELEASE_NAME="stage"

## App directory inside a container.
readonly CONTAINER_APP_DIR='/usr/local/share/subfluent'

## App directory inside a container.
readonly CONTAINER_APP_DATA_DIR="${CONTAINER_APP_DIR}/data"

## Building Docker image with the app inside.
docker build \
  --build-arg APP_DIR="${CONTAINER_APP_DIR}" \
  -t "${IMAGE_NAME}" \
  -f "${SCRIPT_DIR}/tools/docker/Dockerfile" \
  "${SCRIPT_DIR}"

## Pusing Docker image to the Docker registry.
docker push "${IMAGE_NAME}"

helm install --set dataPath="${CONTAINER_APP_DATA_DIR}" "${RELEASE_NAME}" tools/helm
