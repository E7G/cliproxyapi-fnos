#!/bin/bash
# GitHub download helpers with mirror fallback.
#
# Usage:
#   source "$(dirname "$0")/lib/github-mirror.sh"
#   github_download "https://github.com/..." "/path/to/output"
#
# Environment:
#   GH_MIRROR   Mirror base URL (default: auto fallback list).
#               Set to "direct" to skip mirrors and use GitHub only.
#               Example: GH_MIRROR=https://ghfast.top ./build.sh

[ -n "${_GITHUB_MIRROR_LOADED:-}" ] && return 0
_GITHUB_MIRROR_LOADED=1

github_mirror_candidates() {
    if [ -n "${GH_MIRROR:-}" ]; then
        case "${GH_MIRROR}" in
            direct|off|0|false)
                printf '%s\n' ""
                ;;
            *)
                printf '%s\n' "${GH_MIRROR%/}"
                printf '%s\n' ""
                ;;
        esac
        return 0
    fi

    printf '%s\n' \
        "https://ghfast.top" \
        "https://mirror.ghproxy.com" \
        "https://gh-proxy.com" \
        ""
}

github_download() {
    local url="${1:?github_download requires <url>}"
    local dest="${2:?github_download requires <dest>}"
    local mirror url_to_try

    while IFS= read -r mirror; do
        if [ -z "${mirror}" ]; then
            url_to_try="${url}"
            echo "==> Downloading (GitHub direct): ${url}"
        else
            url_to_try="${mirror}/${url}"
            echo "==> Downloading via ${mirror}"
        fi

        if curl -fL \
            --connect-timeout 30 \
            --max-time 600 \
            --retry 2 \
            --retry-delay 3 \
            -o "${dest}" \
            "${url_to_try}"; then
            return 0
        fi

        echo "WARN: download failed (${mirror:-direct}), trying next source..." >&2
        rm -f "${dest}" 2>/dev/null || true
    done < <(github_mirror_candidates)

    echo "ERROR: all GitHub mirrors failed for ${url}" >&2
    return 1
}
