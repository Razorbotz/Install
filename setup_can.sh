#!/bin/bash
#
# deploy_can_gateway.sh
#
# Installs the CAN gateway setup on a fresh Orin Nano:
#   1. mttcan blacklist (so the onboard CAN doesn't claim can0/can1)
#   2. setup_can_gateway.sh (renames USB2CAN dongles, creates vcan, installs cangw rules)
#   3. can-gateway.service (runs the setup script at every boot)
#
# Run from a directory containing all three source files:
#   blacklist-mttcan.conf
#   setup_can_gateway.sh
#   can-gateway.service
#
# Best-effort: keeps going on errors and reports a summary at the end.
# Does NOT reboot -- prints reboot instructions if needed.

# Track which steps succeeded for end-of-run summary.
declare -a successes
declare -a failures
need_reboot=0

step() {
    local name="$1"
    shift
    if "$@"; then
        successes+=("$name")
        echo "  [OK]   $name"
    else
        failures+=("$name")
        echo "  [FAIL] $name"
    fi
}

# Re-exec under sudo if not already root, so the user only types their
# password once instead of in front of every command.
if [ "$EUID" -ne 0 ]; then
    echo "Re-running under sudo..."
    exec sudo bash "$0" "$@"
fi

# Resolve the directory this script lives in, so users can run it from
# anywhere (e.g. ./deploy_can_gateway.sh from a USB stick) and it'll still
# find its sibling files.
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SRC_DIR"

echo "=== CAN gateway deploy ==="
echo "Source directory: $SRC_DIR"
echo

# ---------------------------------------------------------------------------
# 1. Install the mttcan blacklist.
# ---------------------------------------------------------------------------
echo "[1/4] Installing mttcan blacklist..."

if [ ! -f blacklist-mttcan.conf ]; then
    echo "  [FAIL] blacklist-mttcan.conf not found in $SRC_DIR"
    failures+=("blacklist-mttcan.conf source missing")
else
    step "Copy blacklist-mttcan.conf" cp blacklist-mttcan.conf /etc/modprobe.d/blacklist-mttcan.conf
    step "Set perms on blacklist-mttcan.conf" chmod 644 /etc/modprobe.d/blacklist-mttcan.conf
fi

# Regenerate initramfs so the blacklist takes effect at boot. This is the
# step that's easy to forget when doing the install manually.
if command -v update-initramfs > /dev/null 2>&1; then
    step "Regenerate initramfs" update-initramfs -u
else
    echo "  [SKIP] update-initramfs not available on this system"
fi

# Check whether mttcan is currently loaded. If it is, we need a reboot for
# the blacklist to actually take effect.
if lsmod | grep -q "^mttcan "; then
    echo "  [INFO] mttcan is currently loaded -- reboot required for blacklist to take effect"
    need_reboot=1
else
    echo "  [INFO] mttcan is not loaded -- blacklist already in effect"
fi

# ---------------------------------------------------------------------------
# 2. Install the setup script.
# ---------------------------------------------------------------------------
echo
echo "[2/4] Installing setup_can_gateway.sh..."

if [ ! -f setup_can_gateway.sh ]; then
    echo "  [FAIL] setup_can_gateway.sh not found in $SRC_DIR"
    failures+=("setup_can_gateway.sh source missing")
else
    step "Copy setup_can_gateway.sh" cp setup_can_gateway.sh /usr/local/bin/setup_can_gateway.sh
    step "Make setup_can_gateway.sh executable" chmod 755 /usr/local/bin/setup_can_gateway.sh
fi

# ---------------------------------------------------------------------------
# 3. Install the systemd service.
# ---------------------------------------------------------------------------
echo
echo "[3/4] Installing can-gateway.service..."

if [ ! -f can-gateway.service ]; then
    echo "  [FAIL] can-gateway.service not found in $SRC_DIR"
    failures+=("can-gateway.service source missing")
else
    step "Copy can-gateway.service" cp can-gateway.service /etc/systemd/system/can-gateway.service
    step "Set perms on can-gateway.service" chmod 644 /etc/systemd/system/can-gateway.service
    step "systemctl daemon-reload" systemctl daemon-reload
    step "Enable can-gateway.service" systemctl enable can-gateway.service
fi

# ---------------------------------------------------------------------------
# 4. Try to run the setup script now. If mttcan is still loaded, this will
#    likely partially succeed (the defensive can0 cleanup will run) but the
#    full benefit is only realized after reboot. We still try, because if
#    mttcan is NOT loaded (e.g. blacklist already in place from a previous
#    install), we can have the system fully working without a reboot.
# ---------------------------------------------------------------------------
echo
echo "[4/4] Running setup_can_gateway.sh now (best-effort)..."
if [ -x /usr/local/bin/setup_can_gateway.sh ]; then
    step "Run setup_can_gateway.sh" /usr/local/bin/setup_can_gateway.sh
else
    echo "  [SKIP] /usr/local/bin/setup_can_gateway.sh is not executable"
fi

# ---------------------------------------------------------------------------
# Summary.
# ---------------------------------------------------------------------------
echo
echo "=== Summary ==="
echo "Successes: ${#successes[@]}"
echo "Failures:  ${#failures[@]}"
if [ ${#failures[@]} -gt 0 ]; then
    echo
    echo "Failed steps:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
fi

echo
if [ "$need_reboot" -eq 1 ]; then
    echo "============================================================"
    echo " REBOOT REQUIRED"
    echo "============================================================"
    echo " The mttcan kernel module is currently loaded. The blacklist"
    echo " has been installed but will only take effect after a reboot."
    echo
    echo " Run:  sudo reboot"
    echo
    echo " After reboot, verify with:"
    echo "   lsmod | grep mttcan          # should print nothing"
    echo "   ip link show type vcan       # should show can0 (UP)"
    echo "   ip link show type can        # should show can1, can2 (UP)"
    echo "   cangw -L                     # should show 3 rules"
    echo "============================================================"
else
    echo "No reboot required. Verify with:"
    echo "  ip link show type vcan       # should show can0 (UP)"
    echo "  ip link show type can        # should show can1, can2 (UP)"
    echo "  cangw -L                     # should show 3 rules"
fi

# Exit success even if individual steps failed -- best-effort mode.
exit 0