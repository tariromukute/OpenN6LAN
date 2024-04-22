#!/bin/sh

# Copy the config files

mkdir -p /var/lib/suricata/rules/
cp suricata.rules /var/lib/suricata/rules/suricata.rules
cp local.rules /var/lib/suricata/rules/local.rules

cp suricata /etc/default/suricata

# Replace __IF_NAME__ in the config file (suricata.yaml) with the actual interface name
cp suricata.yaml /etc/suricata/suricata.yaml
sed -i 's/__IF_NAME__/eth0-ovs0/g' /etc/suricata/suricata.yaml

# Optional, replace __PLACEHOLDER_FOR_IFCONFIG__ with the yaml configurations for other interfaces