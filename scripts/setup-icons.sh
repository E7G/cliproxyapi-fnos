#!/bin/bash
set -euo pipefail

# Download CLIProxyAPI GitHub org avatar in all fnOS-required sizes.
# Reject the old qBittorrent template placeholder (53e1db...).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FNOS_DIR="${SCRIPT_DIR}/../fnos"
source "${SCRIPT_DIR}/lib/github-mirror.sh"
AVATAR="https://avatars.githubusercontent.com/u/233033915"
IMG_DIR="${FNOS_DIR}/ui/images"
QB_MD5="53e1db100c30b07227aa9a4a3a775ef4"

mkdir -p "${IMG_DIR}"

download_icon() {
    local size="$1"
    local dest="$2"
    github_download "${AVATAR}?s=${size}&v=4" "${dest}.tmp"
    local hash
    hash="$(md5sum "${dest}.tmp" | awk '{print $1}')"
    if [ "${hash}" = "${QB_MD5}" ]; then
        echo "ERROR: icon is still the qBittorrent placeholder (${dest})" >&2
        echo "       Remove fnos/ICON*.PNG and fnos/ui/images/*.png, then rerun build." >&2
        exit 1
    fi
    mv "${dest}.tmp" "${dest}"
}

for stale in "${FNOS_DIR}/ICON.PNG" "${FNOS_DIR}/ICON_256.PNG" "${IMG_DIR}/"*.png; do
    if [ -f "${stale}" ]; then
        hash="$(md5sum "${stale}" | awk '{print $1}')"
        if [ "${hash}" = "${QB_MD5}" ]; then
            echo "Removing stale qBittorrent placeholder: ${stale}" >&2
            rm -f "${stale}"
        fi
    fi
done

for size in 16 32 48 64 128 256; do
    download_icon "${size}" "${IMG_DIR}/${size}.png"
    cp "${IMG_DIR}/${size}.png" "${IMG_DIR}/icon-${size}.png"
    cp "${IMG_DIR}/${size}.png" "${IMG_DIR}/icon_${size}.png"
done

# 应用中心 ICON.PNG 使用 256x256
cp "${IMG_DIR}/256.png" "${FNOS_DIR}/ICON.PNG"
cp "${IMG_DIR}/256.png" "${FNOS_DIR}/ICON_256.PNG"

echo "Icons ready:"
ls -lh "${FNOS_DIR}/ICON.PNG" "${FNOS_DIR}/ICON_256.PNG" "${IMG_DIR}/"*.png
md5sum "${FNOS_DIR}/ICON.PNG" "${FNOS_DIR}/ICON_256.PNG"
