#!/bin/bash
set -e

###############################################################
# CR-ROUTER INITIALIZATION SCRIPT
#
# PURPOSE:
#
# Builds a virtual cyber-range router using:
#
# - Linux network namespaces
# - Linux bridges
# - veth pairs
# - NAT
# - dnsmasq DHCP/DNS
# - tc packet mirroring
#
# NETWORKS:
#
# MGMT   : 10.50.10.0/24
# ATTACK : 10.50.20.0/24
# TARGET : 10.50.30.0/24
#
# MONITORING:
#
# Only TARGET network traffic is mirrored to Security Onion.
#
# DESIGN NOTES:
#
# Mirroring is performed directly to the Security Onion VM TAP
# interface using tc mirred actions.
#
# This avoids Linux bridge forwarding limitations which can
# prevent mirrored packets from reaching the IDS sensor.
###############################################################

echo "[CR-Router] Starting initialization..."

###############################################################
# -1. CLEANUP OLD STATE
###############################################################

if ip netns list | grep -q "CR-router"; then
    echo "[CR-Router] Removing existing namespace..."
    ip netns delete CR-router || true
fi

for v in \
    veth-wan-sw \
    veth-mgmt-sw \
    veth-atk-sw \
    veth-target-sw
do
    if ip link show "$v" >/dev/null 2>&1; then
        echo "[CR-Router] Removing stale interface: $v"
        ip link delete "$v" || true
    fi
done

###############################################################
# 0. ENSURE BRIDGES EXIST
###############################################################
#
# Bridges are intentionally persistent.
#
# These bridges act as the virtual switch fabric for the lab.
###############################################################

for br in \
    CR-mgmt-sw \
    CR-atk-sw \
    CR-target-sw \
    CR-mon-sw
do
    if ! ip link show "$br" >/dev/null 2>&1; then
        echo "[CR-Router] Creating bridge: $br"
        ip link add "$br" type bridge
    fi

    ip link set "$br" up
done

###############################################################
# 1. CREATE ROUTER NAMESPACE
###############################################################

echo "[CR-Router] Creating router namespace..."

ip netns add CR-router

###############################################################
# 1.1 WAN UPLINK
###############################################################
#
# Host provides NAT access to the internet through whichever
# interface currently carries the host default route.
#
# This may be:
#
# - Wi-Fi
# - Ethernet
# - USB tethering
# - another active uplink
#
# HOST SIDE:
#   172.20.0.1/30
#
# ROUTER SIDE:
#   172.20.0.2/30
###############################################################

echo "[CR-Router] Creating WAN uplink..."

ip link add veth-wan-sw type veth peer name veth-wan-rt

ip link set veth-wan-rt netns CR-router

ip addr add 172.20.0.1/30 dev veth-wan-sw

ip link set veth-wan-sw up

ip netns exec CR-router ip addr add 172.20.0.2/30 dev veth-wan-rt
ip netns exec CR-router ip link set veth-wan-rt up

###############################################################
# HOST INTERNET UPLINK DETECTION
###############################################################
#
# Determine which host interface currently carries the default
# route. This avoids hardcoding a specific Wi-Fi, Ethernet, or
# USB-tethering interface name.
###############################################################

HOST_UPLINK=$(ip route show default | awk '
    /default/ {
        for (i = 1; i <= NF; i++) {
            if ($i == "dev") {
                print $(i + 1)
                exit
            }
        }
    }
')

if [ -z "$HOST_UPLINK" ]; then
    echo "[CR-Router] ERROR: No host default-route interface found."
    echo "[CR-Router] Connect Host to an uplink and retry."
    exit 1
fi

echo "[CR-Router] Host internet uplink detected: $HOST_UPLINK"

###############################################################
# HOST NAT
###############################################################
#
# NAT only traffic sourced from the router namespace WAN link.
#
# Restricting the source subnet avoids creating an unnecessarily
# broad host MASQUERADE rule.
###############################################################

iptables -t nat -C POSTROUTING \
    -s 172.20.0.0/30 \
    -o "$HOST_UPLINK" \
    -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING \
    -s 172.20.0.0/30 \
    -o "$HOST_UPLINK" \
    -j MASQUERADE

###############################################################
# DEFAULT ROUTE INSIDE NAMESPACE
###############################################################

ip netns exec CR-router ip route add default via 172.20.0.1

###############################################################
# DNS CONFIGURATION
###############################################################

mkdir -p /etc/netns/CR-router

cat > /etc/netns/CR-router/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

###############################################################
# 2. CREATE INTERNAL NETWORK VETH PAIRS
###############################################################

echo "[CR-Router] Creating internal interfaces..."

###############################################################
# MGMT NETWORK
###############################################################

ip link add veth-mgmt-sw type veth peer name veth-mgmt-rt
ip link set veth-mgmt-rt netns CR-router

###############################################################
# ATTACK NETWORK
###############################################################

ip link add veth-atk-sw type veth peer name veth-atk-rt
ip link set veth-atk-rt netns CR-router

###############################################################
# TARGET NETWORK
###############################################################

ip link add veth-target-sw type veth peer name veth-target-rt
ip link set veth-target-rt netns CR-router

###############################################################
# 3. ATTACH HOST INTERFACES TO BRIDGES
###############################################################

echo "[CR-Router] Attaching interfaces to bridges..."

ip link set veth-mgmt-sw master CR-mgmt-sw
ip link set veth-atk-sw master CR-atk-sw
ip link set veth-target-sw master CR-target-sw

ip link set veth-mgmt-sw up
ip link set veth-atk-sw up
ip link set veth-target-sw up

###############################################################
# 4. CONFIGURE ROUTER INTERFACES
###############################################################

echo "[CR-Router] Configuring router interfaces..."

ip netns exec CR-router ip link set lo up

ip netns exec CR-router ip link set veth-mgmt-rt up
ip netns exec CR-router ip link set veth-atk-rt up
ip netns exec CR-router ip link set veth-target-rt up

###############################################################
# ROUTER GATEWAY ADDRESSES
###############################################################

ip netns exec CR-router ip addr add 10.50.10.254/24 dev veth-mgmt-rt
ip netns exec CR-router ip addr add 10.50.20.254/24 dev veth-atk-rt
ip netns exec CR-router ip addr add 10.50.30.254/24 dev veth-target-rt

###############################################################
# 5. ENABLE ROUTING
###############################################################

echo "[CR-Router] Enabling routing..."

ip netns exec CR-router sysctl -w net.ipv4.ip_forward=1 >/dev/null

###############################################################
# ENABLE NAT INSIDE ROUTER NAMESPACE
###############################################################

ip netns exec CR-router iptables -t nat -C POSTROUTING \
    -o veth-wan-rt -j MASQUERADE 2>/dev/null || \
ip netns exec CR-router iptables -t nat -A POSTROUTING \
    -o veth-wan-rt -j MASQUERADE

###############################################################
# 6. START DNSMASQ
###############################################################
#
# dnsmasq serves the TARGET network.
###############################################################

echo "[CR-Router] Starting dnsmasq..."

mkdir -p /var/lib/dnsmasq-CR-router
mkdir -p /run/dnsmasq-CR-router

ip netns exec CR-router pkill dnsmasq 2>/dev/null || true

ip netns exec CR-router dnsmasq \
    --keep-in-foreground \
    --conf-file=/etc/dnsmasq-CR-router-30.conf &

###############################################################
# 7. SECURITY ONION MIRRORING
###############################################################
#
# TARGET NETWORK ONLY
#
# Mirroring occurs directly to the Security Onion TAP
# interface attached to CR-mon-sw.
#
# This provides:
#
# - full bidirectional visibility
# - reliable IDS packet delivery
# - clean SPAN-port style monitoring
###############################################################

echo "[CR-Router] Configuring Security Onion mirroring..."

###############################################################
# LOCATE SECURITY ONION TAP
###############################################################

SO_TAP=$(bridge link | awk '/master CR-mon-sw/ && /vnet/ {print $2}' | tr -d ':')

if [ -z "$SO_TAP" ]; then
    echo "[CR-Router] ERROR: Security Onion TAP interface not found."
    echo "[CR-Router] Ensure SO sniffing NIC is attached to CR-mon-sw."
    exit 1
fi

echo "[CR-Router] Security Onion TAP detected: $SO_TAP"

###############################################################
# CLEAN OLD TC STATE
###############################################################

tc qdisc del dev veth-target-sw clsact 2>/dev/null || true

###############################################################
# ENABLE CLSACT
###############################################################

tc qdisc add dev veth-target-sw clsact

###############################################################
# MIRROR INGRESS
###############################################################
#
# Captures:
#
# - Target -> Router
# - Target -> Kali
# - Target -> Internet
###############################################################

tc filter add dev veth-target-sw ingress \
    matchall \
    action mirred egress mirror dev "$SO_TAP"

###############################################################
# MIRROR EGRESS
###############################################################
#
# Captures:
#
# - Router -> Target
# - Kali -> Target
# - Internet -> Target
###############################################################

tc filter add dev veth-target-sw egress \
    matchall \
    action mirred egress mirror dev "$SO_TAP"

###############################################################
# COMPLETE
###############################################################

echo
echo "[CR-Router] =========================================="
echo "[CR-Router] Cyber range initialized successfully."
echo "[CR-Router] TARGET network mirroring is ACTIVE."
echo "[CR-Router] Host internet uplink: $HOST_UPLINK"
echo "[CR-Router] Security Onion TAP : $SO_TAP"
echo "[CR-Router] =========================================="
echo
