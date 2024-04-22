#!/bin/sh

apt update
apt install software-properties-common -y
add-apt-repository ppa:oisf/suricata-stable -y
apt install suricata jq -y