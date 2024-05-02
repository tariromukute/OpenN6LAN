#include <linux/bpf.h>
#include <linux/if_ether.h>

#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>
#include "nsh.h"

#define ETH_P_IP 0x0800 /* Internet Protocol packet */
#define ETH_P_NSH	0x894F /* Network Service Header */
#define __section(x) __attribute__((section(x), used))

/* Header cursor to keep track of current parsing position */
struct hdr_cursor {
	void *pos;
};

SEC("xdp_nsh_decap")
int xdp_nsh_decap_fn(struct xdp_md *ctx)
{
    void *data_end = (void *)(unsigned long long)ctx->data_end;
	void *data = (void *)(unsigned long long)ctx->data;
    struct hdr_cursor nh = { .pos = data };

    if (nh.pos + sizeof(struct ethhdr) > data_end)
        return XDP_ABORTED;

    struct ethhdr *eth = nh.pos;
    if (eth->h_proto != bpf_htons(ETH_P_NSH))
        return XDP_PASS;

    struct ethhdr eth_cpy;

    struct nshhdr *nshhdr = nh.pos + sizeof(struct ethhdr);
    // For MD TYPE 2 packets with no metadata, the encap packet needs to be > NSH_M_TYPE1_LEN
    if (nh.pos + sizeof(struct nshhdr) > data_end)
        return XDP_ABORTED;

    __u16 roomlen = nsh_hdr_len(nshhdr);

    if (nh.pos + roomlen > data_end)
        return XDP_ABORTED;

    __builtin_memcpy(&eth_cpy, eth, sizeof(eth_cpy));

	if (bpf_xdp_adjust_head(ctx, (int) roomlen))
		return XDP_ABORTED;
    
    data_end = (void *)(long)ctx->data_end;
    data = (void *)(unsigned long long)ctx->data;
    nh.pos = data;

    if (nh.pos + sizeof(struct ethhdr) > data_end)
		return XDP_ABORTED;

    eth = nh.pos;
    __builtin_memcpy(nh.pos, &eth_cpy, sizeof(struct ethhdr));

    eth->h_proto = bpf_htons(ETH_P_IP);

    return XDP_PASS;
}

char __license[] __section("license") = "GPL";