#!/usr/bin/env bash
set -euo pipefail

APP_NAME="hello-world"
APP_USER="madmax"
APP_HOME="/home/${APP_USER}/${APP_NAME}"
RELEASES_DIR="${APP_HOME}/releases"
CURRENT_LINK="${APP_HOME}/current"
SERVICE_NAME="hello-world"

: "${VERSION:?VERSION is required}"
: "${NEXUS_URL:?NEXUS_URL is required}"
: "${NEXUS_USER:?NEXUS_USER is required}"
: "${NEXUS_REPO:?NEXUS_REPO is required}"

if [ -z "${NEXUS_PASSWORD:-}" ]; then
  echo "Error: NEXUS_PASSWORD is required" >&2
  exit 1
fi

ARCHIVE_NAME="${APP_NAME}_${VERSION}.tar.gz"
ARCHIVE_URL="${NEXUS_URL}/repository/${NEXUS_REPO}/${VERSION}/${ARCHIVE_NAME}"
RELEASE_DIR="${RELEASES_DIR}/${VERSION}"

echo "Deploying ${APP_NAME} version ${VERSION}"
echo "Artifact URL: ${ARCHIVE_URL}"

mkdir -p "${RELEASES_DIR}"
rm -rf "${RELEASE_DIR}"
mkdir -p "${RELEASE_DIR}"

curl --fail --silent --show-error \
  --user "${NEXUS_USER}:${NEXUS_PASSWORD}" \
  --output "${RELEASE_DIR}/${ARCHIVE_NAME}" \
  "${ARCHIVE_URL}"

tar -xzf "${RELEASE_DIR}/${ARCHIVE_NAME}" \
  -C "${RELEASE_DIR}"

rm -f "${RELEASE_DIR}/${ARCHIVE_NAME}"

if [ ! -f "${RELEASE_DIR}/${APP_NAME}_${VERSION}" ]; then
  echo "Error: application binary not found after extraction" >&2
  exit 1
fi

chmod +x "${RELEASE_DIR}/${APP_NAME}_${VERSION}"
mv "${RELEASE_DIR}/${APP_NAME}_${VERSION}" "${RELEASE_DIR}/${APP_NAME}"

if [ ! -x "${RELEASE_DIR}/${APP_NAME}" ]; then
  echo "Error: application binary is not executable after extraction" >&2
  exit 1
fi

sudo cp /home/${APP_USER}/hello-world.service /etc/systemd/system/hello-world.service
sudo systemctl daemon-reload

if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
  PREVIOUS_VERSION="$(readlink -f "${CURRENT_LINK}" 2>/dev/null | xargs basename 2>/dev/null || true)"
else
  PREVIOUS_VERSION=""
fi

ln -sfn "${RELEASE_DIR}" "${CURRENT_LINK}"

sudo systemctl enable "${SERVICE_NAME}.service"
sudo systemctl restart "${SERVICE_NAME}.service"

sleep 3

if ! sudo systemctl is-active --quiet "${SERVICE_NAME}.service"; then
  echo "Error: ${SERVICE_NAME} service is not active after deploy" >&2
  sudo systemctl status "${SERVICE_NAME}.service" --no-pager || true
  exit 1
fi

if [ -n "${PREVIOUS_VERSION:-}" ] && [ "${PREVIOUS_VERSION}" != "${VERSION}" ]; then
  echo "${PREVIOUS_VERSION}" > "${APP_HOME}/previous_version"
  echo "Previous stable version saved: ${PREVIOUS_VERSION}"
else
  echo "No previous stable version available yet"
fi

echo "Deploy completed successfully"
