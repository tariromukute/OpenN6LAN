ip netns add netovs0
ip netns exec netovs0 ip link
ip link add eth0-ovs0 type veth peer name vovs0
ip netns exec netovs0 ip link
ip link set eth0-ovs0 netns netovs0
ip netns exec netovs0 ip link
ip netns exec netovs0 ip r
ovs-vsctl add-br brovs1
#ip link set brovs1 up
ip netns add netovs1
ip netns exec netovs1 ip link
ip link add eth0-ovs1 type veth peer name vovs1
ip netns exec netovs1 ip link
ip link set eth0-ovs1 netns netovs1
ip netns exec netovs1 ip link
ip netns exec netovs1 ip r
ip link set vovs0 nomaster
ip link set vovs1 nomaster
ovs-vsctl add-port brovs1 vovs0
ovs-vsctl add-port brovs1 vovs1
ip link set vovs0 up
ip link set vovs1 up
ip netns exec netovs0 ip link set dev eth0-ovs0 up
ip netns exec netovs0 ip link
ip netns exec netovs0 ip r
ip netns exec netovs1 ip link set dev eth0-ovs1 up
ip netns exec netovs1 ip r
ip netns exec netovs1 ip link
ip netns exec netovs0 ip address add 172.128.2.162/24 dev eth0-ovs0
ip netns exec netovs0 ip link
ip netns exec netovs0 ip a
ip netns exec netovs0 ip r
ip netns exec netovs1 ip address add 172.128.2.163/24 dev eth0-ovs1
ip netns exec netovs1 ip r
ip netns exec netovs1 ip a
# ping -c 4 -i 0.2 172.128.2.163
# ping -c 4 -i 0.2 172.128.2.163
ip a add 172.128.2.1/24 brd + dev brovs1
ip a | grep brovs1
ip r
# ping -c 4 -i 0.2 172.128.2.163
ip netns exec netovs1 ip r
# ping -c 4 -i 0.2 172.128.2.163
ip netns exec netovs1 ip route add default via 172.128.2.1
ip netns exec netovs1 ip r
ip netns exec netovs0 ip route add default via 172.128.2.1
ip netns exec netovs1 ip r
sysctl -w net.ipv4.ip_forward=1
# ping -c 4 -i 0.2 172.128.2.163
# ping -c 4 -i 0.2 172.128.2.162
ip netns exec netovs1 ping -c 4 -i 0.2 172.128.2.162
ip netns exec netovs0 ping -c 4 -i 0.2 172.128.2.163
# Setup for DNS
mkdir -p /etc/netns/netovs0/
echo 'nameserver 8.8.8.8' > /etc/netns/netovs0/resolv.conf
mkdir -p /etc/netns/netovs1/
echo 'nameserver 8.8.8.8' > /etc/netns/netovs1/resolv.conf

# Disable icmp redirects since these are VNFs in gateway scenario
ip netns exec netovs0 sysctl -w net.ipv4.conf.eth0-ovs0.send_redirects=0
ip netns exec netovs0 sysctl -w net.ipv4.conf.all.send_redirects=0

ip netns exec netovs1 sysctl -w net.ipv4.conf.eth0-ovs1.send_redirects=0
ip netns exec netovs1 sysctl -w net.ipv4.conf.all.send_redirects=0