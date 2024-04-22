Set up OVS
```bash
cat /lib/modules/6.6.12-linuxkit/modules.builtin | grep openvswitch

apt install openvswitch-switch openvswitch-common
apt install iproute2 iputils-ping net-tools

export PATH=$PATH:/usr/share/openvswitch/scripts

ovs-ctl start
ovs-vsctl --no-wait init
ovs-vswitchd --pidfile --detach --log-file

ovs-vsctl add-br brovs1

# Run script
ovs-vsctl set bridge brovs1 stp_enable=true
ovs-vsctl set Bridge brovs1 rstp_enable=true

ovs-vsctl add-port brovs1 eth1
ovs-vsctl add-port brovs1 eth2

ovs-vsctl add-port brovs1 eth0
ip addr flush dev eth0 && ip addr add 192.168.72.138/26 dev brovs1 && ip link set brovs1 up
iptables -t nat -A POSTROUTING -o brovs1 -j MASQUERADE
ip route add 12.1.1.0/24 via 192.168.72.134 dev brovs1
ip route add default via 192.168.72.129 dev brovs1

ovs-appctl ofproto/trace brovs1 icmp

ovs-ofctl dump-flows brovs1
ovs-appctl bridge/dump-flows brovs1

# List port numbers and names
ovs-ofctl dump-ports-desc brovs1

# Every Ipv4 packet on eth1 should be sent to SF 1
MAC_ADDRESS=$(ip netns exec netovs0 ip address show eth0-ovs0 | grep link/ether | awk '{print $2}')
ovs-ofctl add-flow brovs1 in_port=3,dl_type=0x0800,actions=mod_dl_dst:${MAC_ADDRESS},output:1
ovs-ofctl add-flow brovs1 in_port=4,dl_type=0x0800,actions=mod_dl_dst:${MAC_ADDRESS},output:1

ovs-ofctl add-flow brovs1 in_port=3,dl_type=0x0800,actions=output:1
ovs-ofctl add-flow brovs1 in_port=3,dl_type=0x894F,actions=output:1
ovs-ofctl add-flow brovs1 in_port=1,dl_type=0x0800,actions=output:3

# Every Ipv4 packet on eth2 should be sent to SF 2
ovs-ofctl add-flow brovs1 in_port=4,dl_type=0x0800,actions=output:2
ovs-ofctl add-flow brovs1 in_port=4,dl_type=0x894F,actions=output:2

Flood of Router Solicitation packets 133
.... ..1. .... .... .... .... = LG bit: Locally administered address (this is NOT the factory default)

# Try removing the gateway
route add default gw 192.168.1.1 br0
route del default gw 192.168.1.1 eth0
```

Network functions

```bash

# Send all packets on eth1 to netovs1
ovs-ofctl add-flow brovs1 in_port=3,dl_type=0x0800,actions=output:2

# Echo back all packets on netovs1
ip netns exec netovs1 ebtables -t broute -A BROUTING -i eth0-ovs1 -j redirect --redirect-target DROP
ip netns exec netovs1 iptables -t nat -A PREROUTING -i eth0-ovs1 -j REDIRECT

# All packets coming out of netovs0 should be normal (just for tracking)
ovs-ofctl add-flow brovs1 in_port=1,dl_type=0x0800,actions=NORMAL

# Allow traffic to flow
iptables -t nat -A POSTROUTING -o eth0-ovs0 -j MASQUERADE
ip route add 192.168.72.0/24 via 172.128.2.162 dev eth0-ovs0

sysctl -w net.ipv4.ip_forward=1

ip netns exec netovs0 iptables -t nat -v -L POSTROUTING
ip netns exec netovs0 sysctl net.ipv4.conf.eth0-ovs0.rp_filter=1

ip netns exec netovs0 sysctl -w net.ipv4.ip_forward=0

# Check if promiscuity is enabled
ip netns exec netovs0 ip -d link

# Enable promiscuity
ip netns exec netovs0 ip link set eth0-ovs0 promisc on

# Check value of ICMP redirects
ip netns exec netovs0 sysctl net.ipv4.conf.eth0-ovs0.send_redirects

# Disable sending of ICMP redirects
ip netns exec netovs0 sysctl -w net.ipv4.conf.eth0-ovs0.send_redirects=0
ip netns exec netovs0 sysctl -w net.ipv4.conf.all.send_redirects=0

# For Suricata
ip netns exec netovs0 iptables -I FORWARD -j NFQUEUE
```

The processing flow diagram by By Jan Engelhardt - Own work, Origin SVG PNG, CC BY-SA 3.0, https://commons.wikimedia.org/w/index.php?curid=8575254

Log packets with iptables to see where packets are being dropped

```bash
# can be read with dmesg(1) or read in the syslog
ip netns exec netovs0 iptables -t raw -I PREROUTING 1 -j NFLOG --nflog-prefix "iptables-raw-prerouting: " --nflog-group 3
ip netns exec netovs0 iptables -t mangle -I PREROUTING 1 -j NFLOG --nflog-prefix "iptables-mangle-prerouting: " --nflog-group 4
ip netns exec netovs0 iptables -t nat -I PREROUTING 1 -j NFLOG --nflog-prefix "iptables-nat-prerouting: " --nflog-group 5

ip netns exec netovs0 iptables -t mangle -I FORWARD 1 -j NFLOG --nflog-prefix "iptables-mangle-forward: " --nflog-group 7
ip netns exec netovs0 iptables -t filter -I FORWARD 1 -j NFLOG --nflog-prefix "iptables-nat-forward: " --nflog-group 8

ip netns exec netovs0 iptables -t nat -I POSTROUTING 1 -j NFLOG --nflog-prefix "iptables-nat-postrouting: " --nflog-group 10
ip netns exec netovs0 iptables -t mangle -I POSTROUTING 1 -j NFLOG --nflog-prefix "iptables-mangle-postrouting: " --nflog-group 11

ip netns exec netovs0 iptables -t mangle -I INPUT 1 -j NFLOG --nflog-prefix "iptables-mangle-input: " --nflog-group 13
ip netns exec netovs0 iptables -t filter -I INPUT 1 -j NFLOG --nflog-prefix "iptables-filter-input: " --nflog-group 14

ip netns exec netovs0 iptables -t raw -I OUTPUT 1 -j NFLOG --nflog-prefix "iptables-raw-output: " --nflog-group 16
ip netns exec netovs0 iptables -t mangle -I OUTPUT 1 -j NFLOG --nflog-prefix "iptables-mangle-output: " --nflog-group 17
ip netns exec netovs0 iptables -t nat -I OUTPUT 1 -j NFLOG --nflog-prefix "iptable-nat-output: " --nflog-group 18
ip netns exec netovs0 iptables -t filter -I OUTPUT 1 -j NFLOG --nflog-prefix "iptables-filter-output: " --nflog-group 19


ip netns exec netovs0 ebtables -t broute -I BROUTING 1 -j NFLOG --nflog-prefix "ebtables-broute-brouting: " --nflog-group 21
ip netns exec netovs0 ebtables -t nat -I PREROUTING 1 -j NFLOG --nflog-prefix "ebtables-broute-brouting: " --nflog-group 22

ip netns exec netovs0 tcpdump -i nflog:<nflog-group> -vvv
```

Identifying the packets that were MAS so that we can send them via the bridge
```bash
iptables -t mangle -A PREROUTING -i eth0 -m conntrack --ctstate SNAT -j NFLOG --nflog-prefix "iptables-conntrack-prerouting: " --nflog-group 25
```
Resources
- How to solve the flooding https://www.net.in.tum.de/fileadmin/TUM/NET/NET-2019-06-1/NET-2019-06-1_09.pdf
http://arthurchiao.art/blog/ovs-unknown-unicast-flooding-under-distributed-gw/
https://netdevconf.info//0.1/docs/netdev_tutorial_bridge_makita_150213.pdf
- NAT'ing with OVS http://www.openvswitch.org/support/ovscon2014/17/1030-conntrack_nat.pdf
- OVS with NAT set up https://matthewarcus.wordpress.com/2018/02/04/veth-devices-network-namespaces-and-open-vswitch/
- Some more NAT'ing exprience https://ilearnedhowto.wordpress.com/tag/nat/
- What Is iptables and How to Use It? https://medium.com/skilluped/what-is-iptables-and-how-to-use-it-781818422e52
- Explanation on iptables rules https://serverfault.com/questions/1101158/create-an-nfqueue-rule-to-match-a-local-addresses-destination-in-my-raspberry-pi
- https://docs.suricata.io/en/latest/setting-up-ipsinline-for-linux.html
- [Suricata in IPS mode dropping tcp traffic](https://forum.suricata.io/t/suricata-in-ips-mode-dropping-tcp-traffic/1335)
- [AF_PACKET IPS mode NOT copy tcp ack packet to another I/F](https://forum.suricata.io/t/af-packet-ips-mode-not-copy-tcp-ack-packet-to-another-i-f/3782)
- [CHARISMA as similar project to N6 LAN](https://ec.europa.eu/research/participants/documents/downloadPublic/ZG9WZHkxRzNibllPVGd0Uys5aVpXUE1Mc2lmdHRYU0N2UWs5NEVEQTVHbzdYSzEyc25pQStBPT0=/attachment/VFEyQTQ4M3ptUWZYTVBpejl0VStaTGxUZFVKT1A1UEM=)

Insprational projects
- https://github.com/onap/demo/tree/master/vnfs
- https://osm.etsi.org/wikipub/index.php/VNFs
- https://www.digitalocean.com/community/tutorials/how-to-configure-suricata-as-an-intrusion-prevention-system-ips-on-debian-11