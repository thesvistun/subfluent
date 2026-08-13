#!/usr/bin/env bash
set -e

fail() {
  echo "$1" >&2
  exit 1
}

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

readonly IMAGE_NAME='my-python-app'

readonly CONTAINER_NAME='app'

## DB file name.
readonly APP_DB_FILENAME='words.db'

## Basic words file name.
readonly APP_BASIC_WORDS_FILENAME='1-1000.txt'

## App directory inside a container.
readonly CONTAINER_APP_DIR='/usr/local/share/subfluent'

## App directory inside a container.
readonly CONTAINER_APP_DATA_DIR="${CONTAINER_APP_DIR}/data"

## DB file path inside a container.
readonly CONTAINER_APP_DB_FILE="${CONTAINER_APP_DATA_DIR}/${APP_DB_FILENAME}"

##  Basic words file inside a container.
readonly CONTAINER_APP_BASIC_WORDS_FILE="${CONTAINER_APP_DATA_DIR}/${APP_BASIC_WORDS_FILENAME}"

readonly VOLUME_NAME=subfluent_data

init_volume() {
  [ $# -lt 2 ] && fail "Usage: init_volume <volume_name> <file1> [file2 ...]"

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

FILES=(
  "${SCRIPT_DIR}/${APP_BASIC_WORDS_FILENAME}"
)

## Initializing Docker volume if doesn't exist.
docker volume inspect "${VOLUME_NAME}" >/dev/null 2>&1 || init_volume "${VOLUME_NAME}" "${FILES[@]}"

## Building Docker image with the app inside.
docker build \
  --build-arg CONTAINER_APP_DIR \
  --build-arg VOLUME_NAME \
  -t "${IMAGE_NAME}" \
  -f "${SCRIPT_DIR}/tools/docker/Dockerfile" \
  "${SCRIPT_DIR}"

## Running the app.
docker run -it --rm \
  -p 8080:5000 \
  -e APP_BASIC_WORDS_FILE="${CONTAINER_APP_BASIC_WORDS_FILE}" \
  -e DB_FILE="${CONTAINER_APP_DB_FILE}" \
  -v "${VOLUME_NAME}":"${CONTAINER_APP_DATA_DIR}" \
  --name "${CONTAINER_NAME}" \
  "${IMAGE_NAME}" $@
