#!/bin/bash
#
# setup_can_gateway.sh
#
# Brings up two USB2CAN interfaces as can1 and can2, plus a virtual can0 used
# as the routing hub. Installs the initial cangw rules so that:
#   - RX from BOTH physical sides bridges into can0 (so motors visible on
#     either side of a bus break still reach the user-space stack).
#   - TX from can0 defaults to can1 (preferred side). AegisGatewayManager
#     replaces this at runtime with per-motor TX rules once it knows which
#     side each motor is reachable on.
#
# Prerequisite: the onboard mttcan driver must be blacklisted (see
# /etc/modprobe.d/blacklist-mttcan.conf) so the onboard CAN controllers don't
# claim the names can0/can1 at boot.
#
# This script is defensive: if a stale physical can0 still exists from a
# previous boot (e.g. blacklist not yet active), it deletes it before
# creating the vcan, so the script is self-healing.

set -e

modprobe vcan
modprobe can-gw

# ---------------------------------------------------------------------------
# Defensive: if can0 exists but is NOT a vcan (e.g. mttcan slipped through),
# delete it so we can create the vcan we actually want.
# ---------------------------------------------------------------------------
if ip link show can0 > /dev/null 2>&1; then
    if ! ip -details link show can0 | grep -q "vcan"; then
        echo "[setup_can_gateway] WARNING: can0 exists as a non-vcan device, deleting"
        ip link set can0 down 2>/dev/null || true
        ip link delete can0 2>/dev/null || true
    fi
fi

# ---------------------------------------------------------------------------
# Normalize physical interface naming: we want the two USB2CAN adapters to
# always come up as can1 and can2. With mttcan blacklisted, the kernel will
# enumerate them as can0 and can1 (since no other CAN devices exist), so we
# shift them to can1 and can2.
#
# If can2 already exists, naming is already correct from a previous setup.
# ---------------------------------------------------------------------------

ip link set can0 down 2>/dev/null || true
ip link set can1 down 2>/dev/null || true
ip link set can2 down 2>/dev/null || true

if ! ip link show can2 > /dev/null 2>&1; then
    # Two physical USB2CAN adapters came up as can0 and can1; shift them.
    ip link set can1 name can2 2>/dev/null || true
    ip link set can0 name can1 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Configure both physical interfaces (can1, can2) at 1 Mbps and bring them up.
# ---------------------------------------------------------------------------

ip link set can1 down 2>/dev/null || true
ip link set can1 type can bitrate 1000000
ifconfig can1 txqueuelen 10000
ip link set can1 up

ip link set can2 down 2>/dev/null || true
ip link set can2 type can bitrate 1000000
ifconfig can2 txqueuelen 10000
ip link set can2 up

# ---------------------------------------------------------------------------
# Create the virtual CAN hub (can0). At this point can0 either does not
# exist (clean state) or exists as a vcan from a previous run.
# ---------------------------------------------------------------------------

if ! ip link show can0 > /dev/null 2>&1; then
    ip link add dev can0 type vcan
fi
ifconfig can0 txqueuelen 10000
ip link set can0 up

# ---------------------------------------------------------------------------
# Install the initial gateway rules:
#   - RX: bridge BOTH physical sides into can0, unfiltered, so status frames
#     from motors on either side of a break still reach user space.
#   - TX: default outbound bridge to can1 (preferred side). AegisGatewayManager
#     replaces this at runtime with per-motor TX rules once it knows which
#     side each motor is reachable on.
# ---------------------------------------------------------------------------

cangw -F
cangw -A -s can1 -d can0 -e
cangw -A -s can2 -d can0 -e
cangw -A -s can0 -d can1 -e

echo "[setup_can_gateway] can1 and can2 up at 1Mbit; can0 vcan up; RX from both sides, TX default to can1"