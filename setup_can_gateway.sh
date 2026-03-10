#!/bin/bash

modprobe vcan
modprobe can-gw

ip link set can0 down
ip link set can1 down
if ! ip link show can2 > /dev/null 2>&1; then
    ip link set can1 name can2 2>/dev/null
    ip link set can0 name can1 2>/dev/null
fi

ip link set can2 down
ip link set can2 type can bitrate 1000000
ifconfig can2 txqueuelen 10000
ip link set can2 up

ip link set can1 down
ip link set can1 type can bitrate 1000000
ifconfig can1 txqueuelen 10000
ip link set can1 up

ip link add dev can0 type vcan
ifconfig can0 txqueuelen 10000
ip link set can0 up

cangw -F 
cangw -A -s can1 -d can0 -e
cangw -A -s can0 -d can1 -e