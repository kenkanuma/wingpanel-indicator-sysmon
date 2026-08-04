#!/usr/bin/env bash
#
# Installs Wingpanel System Monitor from source, including build dependencies.
#
# Usage: ./install.sh

set -euo pipefail

REPO_URL="https://github.com/kenkanuma/wingpanel-indicator-sysmon.git"
BUILD_DIR="build"

if [[ "$(id -u)" -eq 0 ]]; then
    echo "Please run this script as a normal user (it will use sudo when needed)." >&2
    exit 1
fi

if ! command -v apt >/dev/null 2>&1; then
    echo "This script requires apt (elementary OS / Ubuntu / Debian)." >&2
    exit 1
fi

# Detect elementary OS codename to pick the right dependency set.
CODENAME=""
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    CODENAME="${VERSION_CODENAME:-}"
fi

case "$CODENAME" in
    hera)
        DEPS=(libgtop2-dev libgranite-dev libgtk-3-dev libwingpanel-2.0-dev meson valac)
        ;;
    odin|horus)
        DEPS=(libgtop2-dev libgranite-dev libgtk-3-dev libwingpanel-dev libhandy-1-dev meson valac)
        ;;
    circe)
        DEPS=(gettext libgtop2-dev libgranite-dev libgtk-3-dev libwingpanel-dev libhandy-1-dev meson valac)
        ;;
    *)
        echo "Unknown or undetected elementary OS version (codename: '${CODENAME:-unknown}')." >&2
        echo "Falling back to the dependency set for elementary OS 7/8 (Horus/Circe)." >&2
        DEPS=(gettext libgtop2-dev libgranite-dev libgtk-3-dev libwingpanel-dev libhandy-1-dev meson valac)
        ;;
esac

echo "==> Installing build dependencies: ${DEPS[*]}"
sudo apt update
sudo apt install -y git "${DEPS[@]}"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> Cloning $REPO_URL"
git clone --depth 1 "$REPO_URL" "$WORKDIR/wingpanel-indicator-sysmon"
cd "$WORKDIR/wingpanel-indicator-sysmon"

echo "==> Configuring build"
meson setup "$BUILD_DIR" --prefix=/usr

echo "==> Building"
ninja -C "$BUILD_DIR"

echo "==> Installing (sudo required)"
sudo ninja -C "$BUILD_DIR" install

echo "==> Done. Restart Wingpanel or log out/in to see the indicator."
