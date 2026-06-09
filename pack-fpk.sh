#!/bin/bash
set -euo pipefail

pack_fpk() {
  local app_dir="$1"
  local app_tgz="$2"
  local version="$3"
  local platform="$4"
  local out_dir="$5"

  local fnos_dir="${app_dir}/fnos"
  local shared_dir="${app_dir}/shared"
  local appname checksum work_dir pkg_dir fpk_name

  appname="$(grep '^appname' "${fnos_dir}/manifest" | awk -F'=' '{print $2}' | tr -d ' ')"
  checksum="$(md5sum "${app_tgz}" | awk '{print $1}')"

  work_dir="$(mktemp -d)"
  pkg_dir="${work_dir}/package"
  mkdir -p "${pkg_dir}/cmd"

  cp "${app_tgz}" "${pkg_dir}/app.tgz"
  cp "${fnos_dir}/manifest" "${pkg_dir}/manifest"
  sed -i "s/^version.*/version = ${version}/" "${pkg_dir}/manifest"
  if grep -q '^platform' "${pkg_dir}/manifest"; then
    sed -i "s/^platform.*/platform = ${platform}/" "${pkg_dir}/manifest"
  else
    echo "platform = ${platform}" >> "${pkg_dir}/manifest"
  fi
  sed -i "s/^checksum.*/checksum = ${checksum}/" "${pkg_dir}/manifest"

  for f in "${shared_dir}/cmd/"*; do
    case "$(basename "$f")" in
      *.md|*.MD) continue ;;
    esac
    cp "$f" "${pkg_dir}/cmd/"
  done
  cp "${fnos_dir}/cmd/"* "${pkg_dir}/cmd/" 2>/dev/null || true
  cp -a "${fnos_dir}/config" "${pkg_dir}/"
  cp -a "${fnos_dir}/ui" "${pkg_dir}/"
  if [ -f "${fnos_dir}/ui/images/256.png" ]; then
    cp "${fnos_dir}/ui/images/256.png" "${pkg_dir}/ICON.PNG"
    cp "${fnos_dir}/ui/images/256.png" "${pkg_dir}/ICON_256.PNG"
  elif [ -f "${fnos_dir}/ui/images/64.png" ]; then
    cp "${fnos_dir}/ui/images/64.png" "${pkg_dir}/ICON.PNG"
    cp "${fnos_dir}/ui/images/64.png" "${pkg_dir}/ICON_256.PNG"
  else
    cp "${fnos_dir}/ICON.PNG" "${pkg_dir}/ICON.PNG"
    cp "${fnos_dir}/ICON_256.PNG" "${pkg_dir}/ICON_256.PNG"
  fi
  cp "${fnos_dir}/"*.sc "${pkg_dir}/" 2>/dev/null || true
  if [ -d "${app_dir}/var" ]; then
    cp -a "${app_dir}/var" "${pkg_dir}/"
  fi
  if [ -d "${fnos_dir}/wizard" ]; then
    cp -a "${fnos_dir}/wizard" "${pkg_dir}/"
  fi
  if [ -d "${pkg_dir}/ui/images" ]; then
    for size in 16 32 48 64 128 256; do
      src="${pkg_dir}/ui/images/${size}.png"
      [ -f "${src}" ] || continue
      cp "${src}" "${pkg_dir}/ui/images/icon-${size}.png"
      cp "${src}" "${pkg_dir}/ui/images/icon_${size}.png"
    done
    [ -f "${pkg_dir}/ICON_256.PNG" ] && [ ! -f "${pkg_dir}/ui/images/256.png" ] && \
      cp "${pkg_dir}/ICON_256.PNG" "${pkg_dir}/ui/images/256.png"
    [ -f "${pkg_dir}/ICON.PNG" ] && [ ! -f "${pkg_dir}/ui/images/64.png" ] && \
      cp "${pkg_dir}/ICON.PNG" "${pkg_dir}/ui/images/64.png"
  fi

  fpk_name="${appname}_${version}_${platform}.fpk"
  tar -czf "${out_dir}/${fpk_name}" -C "${pkg_dir}" .
  rm -rf "${work_dir}"
  echo "${fpk_name}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  pack_fpk "$1" "$2" "$3" "$4" "$5"
fi
