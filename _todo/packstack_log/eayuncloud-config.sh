#!/usr/bin/env bash

# openstack-utils (openstack-config)
rpm -q openstack-utils || yum install -y openstack-utils

# config
ANSWER_FILE=/root/answers.cfg
CONTROL_PRI_INC=172.16.200.1
CONTROL_PUB_INC=192.168.176.184
DEFAULT_PWD=password


# mysql
openstack-config --set $ANSWER_FILE general CONFIG_MYSQL_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_MYSQL_PW $DEFAULT_PWD

# qpid
openstack-config --set $ANSWER_FILE general CONFIG_QPID_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_QPID_NSS_CERTDB_PW $DEFAULT_PWD
openstack-config --set $ANSWER_FILE general CONFIG_QPID_AUTH_PASSWORD $DEFAULT_PWD

# keystone
openstack-config --set $ANSWER_FILE general CONFIG_KEYSTONE_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_KEYSTONE_DB_PW $DEFAULT_PWD
openstack-config --set $ANSWER_FILE general CONFIG_KEYSTONE_ADMIN_PW $DEFAULT_PWD
openstack-config --set $ANSWER_FILE general CONFIG_KEYSTONE_DEMO_PW $DEFAULT_PWD

# glance
openstack-config --set $ANSWER_FILE general CONFIG_GLANCE_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_GLANCE_DB_PW $DEFAULT_PWD
openstack-config --set $ANSWER_FILE general CONFIG_GLANCE_KS_PW $DEFAULT_PWD

# cinder
openstack-config --set $ANSWER_FILE general CONFIG_CINDER_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_CINDER_DB_PW $DEFAULT_PWD
openstack-config --set $ANSWER_FILE general CONFIG_CINDER_KS_PW $DEFAULT_PWD

# nova
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_API_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_CERT_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_VNCPROXY_HOST $CONTROL_PUB_INC
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_COMPUTE_HOSTS 172.16.200.1,172.16.200.2
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_CONDUCTOR_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_SCHED_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_DB_PW $DEFAULT_PWD
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_KS_PW $DEFAULT_PWD

openstack-config --set $ANSWER_FILE general CONFIG_NOVA_COMPUTE_PRIVIF eth0
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_NETWORK_HOSTS 172.16.200.1,172.16.200.2
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_NETWORK_PUBIF eth1
openstack-config --set $ANSWER_FILE general CONFIG_NOVA_NETWORK_PRIVIF eth0

# neutron
openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_SERVER_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_DB_PW $DEFAULT_PWD
openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_KS_PW $DEFAULT_PWD
openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_L3_HOSTS $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_DHCP_HOSTS $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_METADATA_HOSTS $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_METADATA_PW $DEFAULT_PWD

openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_OVS_TENANT_NETWORK_TYPE vlan
openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_OVS_VLAN_RANGES physnet1:1:4094
openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS physnet1:br-eth0
openstack-config --set $ANSWER_FILE general CONFIG_NEUTRON_OVS_BRIDGE_IFACES br-eth0:eth0

# horizon
openstack-config --set $ANSWER_FILE general CONFIG_OSCLIENT_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_HORIZON_HOST $CONTROL_PRI_INC

# swift

# heat

# ceilometer
openstack-config --set $ANSWER_FILE general CONFIG_CEILOMETER_HOST $CONTROL_PRI_INC
openstack-config --set $ANSWER_FILE general CONFIG_CEILOMETER_KS_PW $DEFAULT_PWD

# nagios
