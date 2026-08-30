#!/usr/bin/env bash
set -e

fail() {
  echo "$1" >&2
  exit 1
}

help() {
  echo "Usage: $0 [--dev] [--help]"
  echo "--dev  Build the Docker images before running it. Otherwise the image from ghcr.io registry is used."
  echo "--help Output this help"
  exit 0
}

build_image() {
  docker build \
    --build-arg VERSION="${APP_VERSION}" \
    --build-arg APP_DIR="${CONTAINER_APP_DIR}" \
    -t "${IMAGE_NAME}:${APP_VERSION}" \
    -f "${SCRIPT_DIR}/tools/docker/Dockerfile" \
    "${SCRIPT_DIR}"
}

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

while [[ $# -gt 0 ]]; do
  case $1 in
    --dev)
      echo "Development mode is activated."
      DEV_MODE=yes
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

readonly BASE_IMAGE_NAME='thesvistun/subfluent'

readonly CONTAINER_NAME='subfluent'

## DB file name.
readonly APP_DB_FILENAME='subfluent.db'

## App directory inside a container.
readonly CONTAINER_APP_DIR='/usr/local/share/subfluent'

## App directory inside a container.
readonly CONTAINER_APP_DATA_DIR="${CONTAINER_APP_DIR}/data"

## DB file path inside a container.
readonly CONTAINER_APP_DB_FILE="${CONTAINER_APP_DATA_DIR}/${APP_DB_FILENAME}"

readonly VOLUME_NAME=subfluent_data

init_volume() {
  [ $# -lt 1 ] && fail "Usage: init_volume <volume_name> [file ...]"

  local volume_name="$1"
  shift
  local files=("$@")

  docker volume create "${volume_name}"

  ## Copy data files to the volume.
  docker create --name helper -v "${volume_name}":/data busybox

  trap 'docker rm -f helper >/dev/null 2>&1 || true' RETURN

  for file in "${files[@]}"; do
    docker cp "${file}" helper:/data/
  done

  docker rm helper
}

## Initializing Docker volume if doesn't exist.
docker volume inspect "${VOLUME_NAME}" >/dev/null 2>&1 || init_volume "${VOLUME_NAME}"

if [[ "${DEV_MODE}" == "yes" ]]; then
  readonly APP_VERSION="$(git describe --tag)"
  readonly IMAGE_NAME="${BASE_IMAGE_NAME}"
  ## Building Docker image with the app inside.
  build_image
else
  readonly APP_VERSION="$(git describe --tag --no-abbrev)"
  readonly IMAGE_NAME="ghcr.io/${BASE_IMAGE_NAME}"
fi

## Running the app.
docker run -it --rm \
  -p 8080:5000 \
  -e DB_FILE="${CONTAINER_APP_DB_FILE}" \
  -v "${VOLUME_NAME}":"${CONTAINER_APP_DATA_DIR}" \
  --name "${CONTAINER_NAME}" \
  "${IMAGE_NAME}:${APP_VERSION}"
