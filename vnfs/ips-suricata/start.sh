service suricata start

sleep 5 # Wait 5 seconds for suricata to start

# Using IPS mode gateway-scenario to send traffic to Suricata
iptables -I FORWARD -j NFQUEUE

# Check if it's running 
service suricata status