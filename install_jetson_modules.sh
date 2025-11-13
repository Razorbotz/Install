#!/bin/bash
# =====================================================================
# Jetson Orin Nano Module Installer (from GitHub)
# Installs prebuilt CAN + Wi-Fi modules into JetPack 6.2.1 system
#
# Usage:
#   sudo ./install_jetson_modules.sh [repo_url] [branch]
# Example:
#   sudo ./install_jetson_modules.sh https://github.com/Razorbotz/Install.git master
#
# Expected repo structure:
#   modules/
#     drivers/net/can/dev/can-dev.ko
#     drivers/net/can/usb/gs_usb.ko
#     drivers/net/wireless/intel/...
#     net/can/*.ko
#     net/wireless/cfg80211.ko
# =====================================================================

set -euo pipefail
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; NC="\033[0m"
ok(){ echo -e "${GREEN}[✓]${NC} $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*"; }
die(){ echo -e "${RED}[✗]${NC} $*" >&2; exit 1; }

# ---------------------------------------------------------------------
# INPUT
# ---------------------------------------------------------------------
REPO_URL="${1:-}"
BRANCH="${2:-main}"

[[ -n "$REPO_URL" ]] || die "Usage: $0 <repo_url> [branch]"
[[ $EUID -eq 0 ]] || die "Please run as root (sudo)."

WORKDIR="/tmp/jetson-modules"
TARGET_BASE="/lib/modules/$(uname -r)/kernel"
VERMAGIC_EXPECTED="$(uname -r)"

# ---------------------------------------------------------------------
# FETCH REPO
# ---------------------------------------------------------------------
echo "-----------------------------------------------------------"
echo "Fetching modules from: $REPO_URL ($BRANCH)"
rm -rf "$WORKDIR"
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$WORKDIR"
[[ -d "$WORKDIR/modules" ]] || die "No 'modules/' directory in repo"
ok "Repository cloned"

# ---------------------------------------------------------------------
# COPY MODULES RECURSIVELY
# ---------------------------------------------------------------------
echo "-----------------------------------------------------------"
echo "Installing to: $TARGET_BASE"
echo "Kernel version: $VERMAGIC_EXPECTED"
echo "-----------------------------------------------------------"

find "$WORKDIR/modules" -type f -name "*.ko" | while read -r SRC; do
    REL_PATH="${SRC#$WORKDIR/modules/}"
    DEST_DIR="${TARGET_BASE}/$(dirname "$REL_PATH")"
    mkdir -p "$DEST_DIR"

    # Verify arch
    if ! file "$SRC" | grep -q "ARM aarch64"; then
        warn "$(basename "$SRC") is not ARM64 — skipping."
        continue
    fi

    # Verify vermagic
    VMAGIC=$(strings "$SRC" | grep -m1 vermagic | cut -d= -f2- | awk '{print $1}')
    if [[ -n "$VMAGIC" && "$VMAGIC" != "$VERMAGIC_EXPECTED" ]]; then
        warn "$(basename "$SRC") vermagic mismatch ($VMAGIC ≠ $VERMAGIC_EXPECTED)"
    fi

    cp -v "$SRC" "$DEST_DIR/"
done

ok "All modules copied successfully"

# ---------------------------------------------------------------------
# UPDATE DEPENDENCIES
# ---------------------------------------------------------------------
depmod -a
ok "Module dependency database updated"

# ---------------------------------------------------------------------
# TEST LOAD
# ---------------------------------------------------------------------
echo
echo "Testing module load (CAN + Wi-Fi)..."
for mod in can can-raw can-dev gs_usb cfg80211 mac80211 iwlwifi; do
    if modprobe "$mod" 2>/dev/null; then
        ok "Loaded $mod"
    else
        warn "Failed to load $mod (check dmesg)"
    fi
done

# ---------------------------------------------------------------------
# AUTOSTART ON BOOT
# ---------------------------------------------------------------------
read -p "Enable modules to auto-load on boot? [y/N]: " reply
if [[ "$reply" =~ ^[Yy]$ ]]; then
    cat <<EOF | tee /etc/modules-load.d/jetson-extra.conf >/dev/null
# CAN
can
can-raw
can-dev
gs_usb
# Wi-Fi
cfg80211
mac80211
iwlwifi
EOF
    ok "Autoload configuration saved → /etc/modules-load.d/jetson-extra.conf"
else
    warn "Autoload skipped"
fi

# ---------------------------------------------------------------------
# CLEANUP
# ---------------------------------------------------------------------
rm -rf "$WORKDIR"
ok "Temporary files removed"
ok "Installation complete!"
echo "-----------------------------------------------------------"
echo "Verify with: lsmod | grep -E 'gs_usb|iwlwifi|can|cfg80211|mac80211'"
echo "-----------------------------------------------------------"
