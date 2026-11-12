#!/usr/bin/env bash
set -euo pipefail

APP_NAME="hello-world"
APP_USER="madmax"
APP_HOME="/home/${APP_USER}/${APP_NAME}"
SERVICE_NAME="hello-world"

echo "Removing ${APP_NAME} deployment"

if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
  systemctl stop "${SERVICE_NAME}.service" || true
  systemctl disable "${SERVICE_NAME}.service" || true
fi

if [ -L "${APP_HOME}/current" ]; then
  rm -f "${APP_HOME}/current"
fi

if [ -f "${APP_HOME}/previous_version" ]; then
  rm -f "${APP_HOME}/previous_version"
fi

if [ -d "${APP_HOME}/releases" ]; then
  rm -rf "${APP_HOME}/releases"
fi

if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
  rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
  systemctl daemon-reload
fi

echo "Removal completed successfully"
