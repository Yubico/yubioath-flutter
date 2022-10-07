#!/bin/bash

#
# Copyright (C) 2022 Yubico.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

DESKTOP_FILENAME="com.yubico.authenticator.desktop"
DESKTOP_FILE="${HOME}/.local/share/applications/${DESKTOP_FILENAME}"

EXEC_DIRNAME=$(dirname "$0")
EXEC_PATH=$(cd "$EXEC_DIRNAME" && pwd)

help() {
  echo "Integrate Yubico Authenticator with common desktop environments."
  echo
  echo "Usage: -i | --install    -- install desktop file"
  echo "       -u | --uninstall  -- uninstall desktop file"
  echo "       -h | --help       -- show usage"
}

install() {
  sed -e "s|@EXEC_PATH|${EXEC_PATH}|g" \
    <"${EXEC_PATH}/linux_support/${DESKTOP_FILENAME}" \
    >"${DESKTOP_FILE}"
  echo "Created file: ${DESKTOP_FILE}"
}

uninstall() {
  rm "${DESKTOP_FILE}"
  echo "Removed: ${DESKTOP_FILE}"
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
  -i | --install)
    install
    exit 0
    ;;
  -u | --uninstall)
    uninstall
    exit 0
    ;;
  -h | --help)
    help
    exit 0
    ;;
  *)
    echo "Unknown parameter passed: $1"
    help
    exit 1
    ;;
  esac
  shift
done

help
