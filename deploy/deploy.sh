#!/usr/bin/env bash
set -euo pipefail

APP_NAME="hello-world"
APP_USER="madmax"
APP_HOME="/home/${APP_USER}/${APP_NAME}"
RELEASES_DIR="${APP_HOME}/releases"
CURRENT_LINK="${APP_HOME}/current"
CURRENT_VERSION_FILE="${APP_HOME}/current_version"
PREVIOUS_VERSION_FILE="${APP_HOME}/previous_version"
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

PREVIOUS_VERSION=""

if [ -f "${CURRENT_VERSION_FILE}" ]; then
  CANDIDATE_VERSION="$(cat "${CURRENT_VERSION_FILE}" || true)"

  if [ -n "${CANDIDATE_VERSION}" ] && \
     [ "${CANDIDATE_VERSION}" != "${VERSION}" ] && \
     [ -d "${RELEASES_DIR}/${CANDIDATE_VERSION}" ]; then
    PREVIOUS_VERSION="${CANDIDATE_VERSION}"
  fi
fi

if [ -d "${CURRENT_LINK}" ] && [ ! -L "${CURRENT_LINK}" ]; then
  echo "Removing legacy current directory: ${CURRENT_LINK}"
  rm -rf "${CURRENT_LINK}"
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

if [ -n "${PREVIOUS_VERSION}" ]; then
  echo "${PREVIOUS_VERSION}" > "${PREVIOUS_VERSION_FILE}"
  echo "Previous stable version saved: ${PREVIOUS_VERSION}"
else
  rm -f "${PREVIOUS_VERSION_FILE}"
  echo "No previous stable version available yet"
fi

echo "${VERSION}" > "${CURRENT_VERSION_FILE}"

echo "Deploy completed successfully"
