#!/bin/bash
set -euo pipefail

# Generate distinctive CLIProxyAPI icons locally (no qBittorrent template / avatar cache).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FNOS_DIR="${SCRIPT_DIR}/../fnos"
IMG_DIR="${FNOS_DIR}/ui/images"
QB_MD5="53e1db100c30b07227aa9a4a3a775ef4"

mkdir -p "${IMG_DIR}"

icon_md5() {
    md5sum "$1" | awk '{print $1}'
}

icons_look_valid() {
    local f hash
    for f in "${FNOS_DIR}/ICON.PNG" "${FNOS_DIR}/ICON_256.PNG" "${IMG_DIR}/64.png" "${IMG_DIR}/256.png"; do
        [ -f "${f}" ] || return 1
        hash="$(icon_md5 "${f}")"
        [ "${hash}" != "${QB_MD5}" ] || return 1
    done
    for size in 16 32 48 64 128 256; do
        [ -f "${IMG_DIR}/${size}.png" ] || return 1
    done
    return 0
}

seed_icons_from_existing() {
    local size base
    [ -f "${IMG_DIR}/64.png" ] || return 1
    [ -f "${IMG_DIR}/256.png" ] || return 1
    for size in 16 32 48; do
        cp "${IMG_DIR}/64.png" "${IMG_DIR}/${size}.png"
        cp "${IMG_DIR}/${size}.png" "${IMG_DIR}/icon-${size}.png"
        cp "${IMG_DIR}/${size}.png" "${IMG_DIR}/icon_${size}.png"
    done
    for size in 64 128 256; do
        base="$([ "${size}" -le 64 ] && echo 64 || echo 256)"
        [ -f "${IMG_DIR}/${size}.png" ] || cp "${IMG_DIR}/${base}.png" "${IMG_DIR}/${size}.png"
        cp "${IMG_DIR}/${size}.png" "${IMG_DIR}/icon-${size}.png"
        cp "${IMG_DIR}/${size}.png" "${IMG_DIR}/icon_${size}.png"
    done
    sync_appcenter_icons
    return 0
}

sync_appcenter_icons() {
    # 应用中心 ICON.PNG 建议使用 256x256（fnOS 规范）
    if [ -f "${IMG_DIR}/256.png" ]; then
        cp -fp "${IMG_DIR}/256.png" "${FNOS_DIR}/ICON.PNG"
        cp -fp "${IMG_DIR}/256.png" "${FNOS_DIR}/ICON_256.PNG"
    elif [ -f "${IMG_DIR}/64.png" ]; then
        cp -fp "${IMG_DIR}/64.png" "${FNOS_DIR}/ICON.PNG"
        cp -fp "${IMG_DIR}/64.png" "${FNOS_DIR}/ICON_256.PNG"
    fi
}

if icons_look_valid; then
    sync_appcenter_icons
    echo "Icons already present, synced app-center ICON.PNG"
    exit 0
fi

if seed_icons_from_existing && icons_look_valid; then
    echo "Seeded missing icon sizes from existing assets"
    ls -lh "${FNOS_DIR}/ICON.PNG" "${FNOS_DIR}/ICON_256.PNG" "${IMG_DIR}/"*.png
    exit 0
fi

render_icon() {
    local size="$1"
    local dest="$2"
    python3 - "$size" "$dest" <<'PY'
import sys

size = int(sys.argv[1])
path = sys.argv[2]

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit(2)

img = Image.new("RGBA", (size, size), (15, 118, 110, 255))
draw = ImageDraw.Draw(img)
margin = max(4, size // 16)
draw.rounded_rectangle(
    (margin, margin, size - margin - 1, size - margin - 1),
    radius=max(6, size // 8),
    fill=(16, 185, 129, 255),
)

font_size = max(12, size // 3)
try:
    font = ImageFont.truetype("DejaVuSans-Bold.ttf", font_size)
except OSError:
    font = ImageFont.load_default()

text = "CP"
bbox = draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
draw.text(
    ((size - tw) // 2, (size - th) // 2 - max(1, size // 32)),
    text,
    fill=(255, 255, 255, 255),
    font=font,
)
img.save(path, format="PNG")
PY
}

write_with_convert() {
    local size="$1"
    local dest="$2"
    local point=$((size * 2 / 5))
    convert -size "${size}x${size}" "xc:#0f766e" \
        -fill "#10b981" -draw "roundrectangle 4,4 $((size-5)),$((size-5)) $((size/8)),$((size/8))" \
        -gravity center -fill white -font DejaVu-Sans-Bold -pointsize "${point}" \
        -annotate 0 'CP' "${dest}"
}

for size in 16 32 48 64 128 256; do
    dest="${IMG_DIR}/${size}.png"
    if render_icon "${size}" "${dest}" 2>/dev/null; then
        :
    elif command -v convert >/dev/null 2>&1; then
        write_with_convert "${size}" "${dest}"
    else
        echo "ERROR: need python3-pil or imagemagick to generate icons" >&2
        exit 1
    fi
    cp "${dest}" "${IMG_DIR}/icon-${size}.png"
    cp "${dest}" "${IMG_DIR}/icon_${size}.png"
done

sync_appcenter_icons

echo "Generated icons:"
ls -lh "${FNOS_DIR}/ICON.PNG" "${FNOS_DIR}/ICON_256.PNG" "${IMG_DIR}/"*.png
md5sum "${FNOS_DIR}/ICON.PNG" "${FNOS_DIR}/ICON_256.PNG"
