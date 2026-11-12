#!/usr/bin/env bash
set -euo pipefail

APP_NAME="hello-world"
APP_USER="madmax"
APP_HOME="/home/${APP_USER}/${APP_NAME}"
RELEASES_DIR="${APP_HOME}/releases"
CURRENT_LINK="${APP_HOME}/current"
PREVIOUS_VERSION_FILE="${APP_HOME}/previous_version"
SERVICE_NAME="hello-world"

if [ ! -f "${PREVIOUS_VERSION_FILE}" ]; then
  echo "Error: previous stable version is not defined" >&2
  exit 1
fi

PREVIOUS_VERSION="$(cat "${PREVIOUS_VERSION_FILE}")"

if [ -z "${PREVIOUS_VERSION}" ]; then
  echo "Error: previous stable version is empty" >&2
  exit 1
fi

PREVIOUS_RELEASE_DIR="${RELEASES_DIR}/${PREVIOUS_VERSION}"

if [ ! -d "${PREVIOUS_RELEASE_DIR}" ]; then
  echo "Error: previous release directory does not exist: ${PREVIOUS_RELEASE_DIR}" >&2
  exit 1
fi

if [ ! -f "${PREVIOUS_RELEASE_DIR}/${APP_NAME}_${PREVIOUS_VERSION}" ] && \
   [ ! -f "${PREVIOUS_RELEASE_DIR}/${APP_NAME}" ]; then
  echo "Error: previous application binary does not exist" >&2
  exit 1
fi

if [ ! -f "${PREVIOUS_RELEASE_DIR}/${APP_NAME}" ]; then
  chmod +x "${PREVIOUS_RELEASE_DIR}/${APP_NAME}_${PREVIOUS_VERSION}"
  mv "${PREVIOUS_RELEASE_DIR}/${APP_NAME}_${PREVIOUS_VERSION}" \
     "${PREVIOUS_RELEASE_DIR}/${APP_NAME}"
fi

if [ ! -x "${PREVIOUS_RELEASE_DIR}/${APP_NAME}" ]; then
  echo "Error: previous application binary is not executable" >&2
  exit 1
fi

CURRENT_VERSION="$(readlink -f "${CURRENT_LINK}" 2>/dev/null | xargs basename 2>/dev/null || true)"

if [ "${CURRENT_VERSION}" = "${PREVIOUS_VERSION}" ]; then
  echo "Previous version is already active: ${PREVIOUS_VERSION}"
  exit 0
fi

echo "Rolling back from ${CURRENT_VERSION:-unknown} to ${PREVIOUS_VERSION}"

ln -sfn "${PREVIOUS_RELEASE_DIR}" "${CURRENT_LINK}"

sudo systemctl restart "${SERVICE_NAME}.service"

sleep 3

if ! sudo systemctl is-active --quiet "${SERVICE_NAME}.service"; then
  echo "Error: ${SERVICE_NAME} service is not active after rollback" >&2
  sudo systemctl status "${SERVICE_NAME}.service" --no-pager || true
  exit 1
fi

echo "Rollback completed successfully"
echo "Active version: ${PREVIOUS_VERSION}"
