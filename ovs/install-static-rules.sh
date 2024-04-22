#!/bin/sh

# Every Ipv4 packet on eth1 should be sent to SF 1
MAC_ADDRESS=$(ip netns exec netovs0 ip address show eth0-ovs0 | grep link/ether | awk '{print $2}')
ovs-ofctl add-flow brovs1 in_port=3,dl_type=0x0800,actions=mod_dl_dst:${MAC_ADDRESS},output:1
ovs-ofctl add-flow brovs1 in_port=4,dl_type=0x0800,actions=mod_dl_dst:${MAC_ADDRESS},output:1
# When vCache (squid) response from cache, it will have the Gateway MAC address as the dest mac. This will
# cause the gateway to respond with it's IP as the source IP. This will cause the TCP flow to fail. To resolve
# this, we need to modify the vCache responses to put the MAC of the client.
ovs-ofctl add-flow brovs1 in_port=1,dl_type=0x0800,nw_dst=192.168.72.128/26,actions=mod_dl_dst:02:42:ac:11:65:43,NORMAL

# All packets coming out of netovs0 should be normal (just for tracking)
# ovs-ofctl add-flow brovs1 in_port=1,dl_type=0x0800,actions=NORMAL