#!/bin/sh

# Copy config files
cp squid.conf /etc/squid/

# your proxy listening port
SQUIDPORT=3129

CLIENTIFACE=eth0-ovs0

iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $SQUIDPORT
iptables -t mangle -A PREROUTING -p tcp --dport $SQUIDPORT -j DROP