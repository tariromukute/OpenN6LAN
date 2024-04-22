#!/bin/sh

IFACE=eth0-ovs0
# Copy config files
cp squid.conf /etc/squid/

ip -f inet rule add fwmark 1 lookup 100
ip -f inet route add local default dev ${IFACE} table 100

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.default.rp_filter=0
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.${IFACE}.rp_filter=0

# Setup a chain DIVERT to mark packets
iptables -t mangle -N DIVERT
iptables -t mangle -A DIVERT -j MARK --set-mark 1
iptables -t mangle -A DIVERT -j ACCEPT

# Use DIVERT to prevent existing connections going through TPROXY twice
iptables  -t mangle -A PREROUTING -p tcp -m socket -j DIVERT

# Mark all other (new) packets and use TPROXY to pass into Squid
iptables  -t mangle -A PREROUTING -p tcp --dport 80 -j TPROXY --tproxy-mark 0x1/0x1 --on-port 3129

