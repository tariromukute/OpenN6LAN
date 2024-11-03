# Evaluate performance using Cisco TREX

## Get Started

**Build**

```bash
docker buildx build --platform=linux/amd64 -t tariromukute/cisco-trex:latest -f docker/Dockerfile.trex .

docker buildx build --platform=linux/amd64 -t tariromukute/router:latest -f docker/Dockerfile.router .
```

**Config**

The configuration for TREX in the router test scenario can be found in `docker-compose/conf/trex_rtr_cfg.yaml`. For some reason, is the management interface for TREX is not eth0, you receive a double count on the received packets on one of the packets. Need to make sure that the naming of the networks in docker compose results in the management interface being eth0 i.e., the name of the network with the management interface should be the first in terms of aphabetic order.

**Run TREX with DUT**

```bash
# Launch a shell inside the trex container
docker compose -f docker-compose-trex-dut.yaml exec trex /bin/bash

# Start the interactive trex console which will make a local connection to the running interactive daemon
./trex-console

# Start generating some traffic
start -f stl/imix.py

# To interact with and view statistics for the current stream launch the text-based user interface (tui)
tui

# Attempt to increase per interface traffic rate to 200mbps (400mbps rx/tx total). Throughput achievable in the Docker environment is dependent primarily on single core\thread CPU performance.
update -m 200mbps

docker compose -f docker-compose-trex-dut.yaml down
```

## Send from single interface

To use a single interface we configure TREX to use a dummy interface for the second interface. See `docker-compose/conf/trex_rtr_tx_cfg.yaml`.

