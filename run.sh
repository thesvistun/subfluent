#!/usr/bin/env bash
set -e

fail() {
  echo "$1" >&2
  exit 1
}

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

## DB file name. Used in Python app as well.
export APP_DB_FILE='words.db'

if [ ! -f "${APP_DB_FILE}" ]; then
  ## Fail if sqlite3 isn't installed.
  sqlite3 --version >/dev/null 2>&1 || fail 'sqlite3 not found, but required to run this application.'
  ## Creating default DB.
  sqlite3 "${SCRIPT_DIR}/${APP_DB_FILE}" ''
fi

docker build -t my-python-app ${SCRIPT_DIR}/tools/docker/
docker run -it --rm -p 8080:5000 -e APP_DB_FILE -v ${SCRIPT_DIR}:${SCRIPT_DIR} -w ${SCRIPT_DIR} --name app my-python-app $@
