FROM ubuntu:jammy

WORKDIR /app

RUN apt-get update && \
    apt-get install -y iproute2 iputils-ping tcpdump net-tools iptables \
    openvswitch-switch openvswitch-common

RUN DEBIAN_FRONTEND=noninteractive apt install software-properties-common --yes && \
    add-apt-repository ppa:oisf/suricata-stable -y && \
    apt install suricata -y

COPY ./testovs.sh /app/testovs.sh
COPY ./entrypoint.sh /app/entrypoint.sh

COPY vnfs /app/vnfs
COPY ovs /app/ovs

ENTRYPOINT [ "sh", "/app/entrypoint.sh" ]