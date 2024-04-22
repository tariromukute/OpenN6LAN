#!/bin/sh

# Every Ipv4 packet on eth1 should be sent to SF 1
MAC0_ADDRESS=$(ip netns exec netovs0 ip address show eth0-ovs0 | grep link/ether | awk '{print $2}')
MAC1_ADDRESS=$(ip netns exec netovs1 ip address show eth0-ovs1 | grep link/ether | awk '{print $2}')

# Forward path
ovs-ofctl add-flow brovs1 priority=10,in_port=3,dl_type=0x0800,actions=mod_dl_dst:${MAC0_ADDRESS},output:1
ovs-ofctl add-flow brovs1 priority=7,in_port=1,dl_type=0x0800,actions=mod_dl_dst:${MAC1_ADDRESS},output:2
ovs-ofctl add-flow brovs1 priority=4,in_port=2,dl_type=0x0800,actions=NORMAL

# Return path
ovs-ofctl add-flow brovs1 priority=9,in_port=4,dl_type=0x0800,actions=mod_dl_dst:${MAC1_ADDRESS},output:2
ovs-ofctl add-flow brovs1 priority=6,in_port=2,dl_type=0x0800,nw_dst=192.168.72.128/26,actions=mod_dl_dst:${MAC0_ADDRESS},output:1
ovs-ofctl add-flow brovs1 priority=5,in_port=2,dl_type=0x0800,nw_dst=172.128.2.1/24,actions=mod_dl_dst:${MAC0_ADDRESS},output:1
# When vCache (squid) response from cache, it will have the Gateway MAC address as the dest mac. This will
# cause the gateway to respond with it's IP as the source IP. This will cause the TCP flow to fail. To resolve
# this, we need to modify the vCache responses to put the MAC of the client.
ovs-ofctl add-flow brovs1 priority=8,in_port=1,dl_type=0x0800,nw_dst=192.168.72.128/26,actions=mod_dl_dst:02:42:ac:11:65:43,NORMAL

# All packets coming out of netovs0 should be normal (just for tracking)
# ovs-ofctl add-flow brovs1 in_port=1,dl_type=0x0800,actions=NORMAL