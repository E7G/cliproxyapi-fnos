#!/bin/bash
set -euo pipefail

# Build CLIProxyAPI Plus + CPA-Manager-Plus fnOS fpk (native binaries, no Docker)
# Usage: ./build.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FNOS_DIR="${SCRIPT_DIR}/fnos"
OUT_DIR="${SCRIPT_DIR}/dist"
VERSION="7.1.45-0.4"
ARCH="linux_amd64"
FNOS_PLATFORM="x86"
BINARY_NAME="CLIProxyAPIPlus"
MANAGER_BINARY_NAME="cpa-manager-plus"

UPSTREAM_REPO="kaitranntt/CLIProxyAPIPlus"
UPSTREAM_VERSION="7.1.45-0"
CPA_ASSET="${BINARY_NAME}_${UPSTREAM_VERSION}_${ARCH}.tar.gz"
CPA_URL="https://github.com/${UPSTREAM_REPO}/releases/download/v${UPSTREAM_VERSION}/${CPA_ASSET}"

MANAGER_REPO="seakee/CPA-Manager-Plus"
MANAGER_VERSION="1.2.1"
MANAGER_ASSET="${MANAGER_BINARY_NAME}_v${MANAGER_VERSION}_${ARCH}.tar.gz"
MANAGER_URL="https://github.com/${MANAGER_REPO}/releases/download/v${MANAGER_VERSION}/${MANAGER_ASSET}"

source "${SCRIPT_DIR}/scripts/lib/github-mirror.sh"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

echo "==> Downloading CLIProxyAPI Plus ${UPSTREAM_VERSION}"
github_download "${CPA_URL}" "${WORK_DIR}/${CPA_ASSET}"
tar -xzf "${WORK_DIR}/${CPA_ASSET}" -C "${WORK_DIR}"

BIN="$(find "${WORK_DIR}" -type f \( -name "${BINARY_NAME}" -o -name cli-proxy-api-plus -o -name CLIProxyAPI -o -name cli-proxy-api \) | head -n 1)"
[ -n "${BIN}" ] || { echo "${BINARY_NAME} binary not found in archive" >&2; exit 1; }

echo "==> Downloading CPA-Manager-Plus ${MANAGER_VERSION}"
github_download "${MANAGER_URL}" "${WORK_DIR}/${MANAGER_ASSET}"
tar -xzf "${WORK_DIR}/${MANAGER_ASSET}" -C "${WORK_DIR}"

MANAGER_BIN="$(find "${WORK_DIR}" -type f \( -name "${MANAGER_BINARY_NAME}" -o -name "cpa-manager-plus" \) | head -n 1)"
[ -n "${MANAGER_BIN}" ] || { echo "${MANAGER_BINARY_NAME} binary not found in archive" >&2; exit 1; }

echo "==> Generating icons"
bash "${SCRIPT_DIR}/scripts/generate-icons.sh"

echo "==> Generating install wizard (pre-install credentials)"
bash "${SCRIPT_DIR}/scripts/generate-install-wizard.sh"

echo "==> Preparing app data seed (var/)"
mkdir -p "${SCRIPT_DIR}/var/auths" "${SCRIPT_DIR}/var/logs"
rm -rf "${SCRIPT_DIR}/var/static"

echo "==> Preparing app.tgz"
APP_ROOT="${WORK_DIR}/app_root"
mkdir -p "${APP_ROOT}/bin" "${APP_ROOT}/ui/images"

cp "${BIN}" "${APP_ROOT}/bin/${BINARY_NAME}"
chmod +x "${APP_ROOT}/bin/${BINARY_NAME}"
cp "${MANAGER_BIN}" "${APP_ROOT}/bin/${MANAGER_BINARY_NAME}"
chmod +x "${APP_ROOT}/bin/${MANAGER_BINARY_NAME}"
cp -a "${FNOS_DIR}/ui/." "${APP_ROOT}/ui/"
if [ -f "${FNOS_DIR}/ui/images/256.png" ]; then
  cp "${FNOS_DIR}/ui/images/256.png" "${APP_ROOT}/ICON.PNG"
  cp "${FNOS_DIR}/ui/images/256.png" "${APP_ROOT}/ICON_256.PNG"
else
  cp "${FNOS_DIR}/ui/images/64.png" "${APP_ROOT}/ICON.PNG"
  cp "${FNOS_DIR}/ui/images/64.png" "${APP_ROOT}/ICON_256.PNG"
fi
cp "${SCRIPT_DIR}/var/config.example.yaml" "${APP_ROOT}/config.example.yaml"

APP_TGZ="${WORK_DIR}/app.tgz"
tar -czf "${APP_TGZ}" -C "${APP_ROOT}" .

echo "==> Building fpk (${FNOS_PLATFORM})"
mkdir -p "${OUT_DIR}"
FPK_NAME="$(bash "${SCRIPT_DIR}/pack-fpk.sh" "${SCRIPT_DIR}" "${APP_TGZ}" "${VERSION}" "${FNOS_PLATFORM}" "${OUT_DIR}")"
echo "==> Built ${OUT_DIR}/${FPK_NAME}"
