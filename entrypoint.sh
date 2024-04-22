export PATH=$PATH:/usr/share/openvswitch/scripts

ovs-ctl start
ovs-vsctl --no-wait init
ovs-vswitchd --pidfile --detach --log-file

# sh testovs.sh

exec "$@"