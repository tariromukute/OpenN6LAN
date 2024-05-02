ARG BASE_IMAGE=ubuntu:jammy
FROM $BASE_IMAGE as builder
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /bpf

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes && \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes \
    clang \
    llvm \
    libbpf-dev \
  && rm -rf /var/lib/apt/lists/*

COPY bpf ./

RUN clang -O2 -emit-llvm -g -c nsh-decap.bpf.c -o - | \
	llc -march=bpf -mcpu=probe -filetype=obj -o nsh-decap.bpf.o

FROM $BASE_IMAGE AS n6-lan

RUN apt-get update && \
    apt-get install -y iproute2 iputils-ping tcpdump net-tools iptables \
    openvswitch-switch openvswitch-common

RUN DEBIAN_FRONTEND=noninteractive apt install software-properties-common --yes && \
    add-apt-repository ppa:oisf/suricata-stable -y && \
    apt install suricata -y

WORKDIR /app

COPY --from=builder /bpf/nsh-decap.bpf.o .

COPY ./testovs.sh /app/testovs.sh
COPY ./entrypoint.sh /app/entrypoint.sh

COPY vnfs /app/vnfs
COPY ovs /app/ovs

ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]