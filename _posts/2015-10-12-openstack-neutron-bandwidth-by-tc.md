---
layout: post
category: openstack
title: Openstack neutron bandwidth/QOS by linux TC
tags: [linux, openstack]

---



### Openstack QOS by Linux TC

#### 1. tc [Traffic Control](http://linuxcommand.org/man_pages/tc8.html)

Linux操作系统中的流量控制器TC（Traffic Control）用于Linux内核的流量控制，主要是通过在***输出***端口处建立一个队列来实现流量控制。

要实现nova instance的QOS，可以通过在linux bridge的qvbxxxx端口限制instance出口流量，在ovs bridge上的qvoxxxx端口限制instance的入口流量，并添加filter过滤tenant内部网络流量不受QOS限制。
    

#### 2. get metadata for TC rule

    root@node-4:~# cat /etc/lsb-release 
    DISTRIB_ID=Ubuntu
    DISTRIB_RELEASE=14.04
    DISTRIB_CODENAME=trusty
    DISTRIB_DESCRIPTION="Ubuntu 14.04.3 LTS"


##### 2.1 show instance info

    root@node-1:~# nova show 95985dfe-8356-4bb6-8ec7-46730d1b4c41 | grep host
    
    +--------------------------------------+----------------------------------------------------------+
    | Property                             | Value                                                    |
    +--------------------------------------+----------------------------------------------------------+
    | OS-DCF:diskConfig                    | AUTO                                                     |
    | OS-EXT-AZ:availability_zone          | nova                                                     |
    | OS-EXT-SRV-ATTR:host                 | node-4.domain.tld                                        |
    | OS-EXT-SRV-ATTR:hypervisor_hostname  | node-4.domain.tld                                        |
    | OS-EXT-SRV-ATTR:instance_name        | instance-00000039                                        |
    | OS-EXT-STS:power_state               | 1                                                        |
    | OS-EXT-STS:task_state                | -                                                        |
    | OS-EXT-STS:vm_state                  | active                                                   |
    | OS-SRV-USG:launched_at               | 2015-10-19T02:22:12.000000                               |
    | OS-SRV-USG:terminated_at             | -                                                        |
    | accessIPv4                           |                                                          |
    | accessIPv6                           |                                                          |
    | config_drive                         |                                                          |
    | created                              | 2015-10-19T02:21:50Z                                     |
    | flavor                               | m1.micro (0eefecd0-97e4-4516-809e-90f85a9a03f3)          |
    | hostId                               | c3d0268a383dcc25cedf8853096e472d36a34b91908f299c6634c176 |
    | id                                   | 95985dfe-8356-4bb6-8ec7-46730d1b4c41                     |
    | image                                | TestVM (82f4c727-5b18-427f-9094-0f92eed5607e)            |
    | key_name                             | -                                                        |
    | metadata                             | {}                                                       |
    | name                                 | tc-test-by-zhanghui                                      |
    | net04 network                        | 192.168.111.14                                           |
    | os-extended-volumes:volumes_attached | []                                                       |
    | progress                             | 0                                                        |
    | security_groups                      | default                                                  |
    | status                               | ACTIVE                                                   |
    | tenant_id                            | ba7a2c788ab849e0a583cf54bec0a1f4                         |
    | updated                              | 2015-10-19T02:22:12Z                                     |
    | user_id                              | e36dfa5518fe42bfa753c59674b6ed59                         |
    +--------------------------------------+----------------------------------------------------------+
    
##### 2.2 list instance port

    root@node-1:~# nova interface-list 95985dfe-8356-4bb6-8ec7-46730d1b4c41
    
    +------------+--------------------------------------+--------------------------------------+----------------+-------------------+
    | Port State | Port ID                              | Net ID                               | IP addresses   | MAC Addr          |
    +------------+--------------------------------------+--------------------------------------+----------------+-------------------+
    | ACTIVE     | fc618310-b936-4247-a5e4-2389a9d8c50e | de2df80a-5f69-4630-85ac-4081ce70de98 | 192.168.111.14 | fa:16:3e:5e:99:0c |
    +------------+--------------------------------------+--------------------------------------+----------------+-------------------+

##### 2.3 show port info 

    root@node-1:~# neutron port-show fc618310-b936-4247-a5e4-2389a9d8c50e
    
    +-----------------------+---------------------------------------------------------------------------------------+
    | Field                 | Value                                                                                 |
    +-----------------------+---------------------------------------------------------------------------------------+
    | admin_state_up        | True                                                                                  |
    | allowed_address_pairs |                                                                                       |
    | binding:host_id       | node-4.domain.tld                                                                     |
    | binding:profile       | {}                                                                                    |
    | binding:vif_details   | {"port_filter": true, "ovs_hybrid_plug": true}                                        |
    | binding:vif_type      | ovs                                                                                   |
    | binding:vnic_type     | normal                                                                                |
    | device_id             | 95985dfe-8356-4bb6-8ec7-46730d1b4c41                                                  |
    | device_owner          | compute:nova                                                                          |
    | extra_dhcp_opts       |                                                                                       |
    | fixed_ips             | {"subnet_id": "d75307b5-137f-4fd4-8c30-17974a8489a3", "ip_address": "192.168.111.14"} |
    | id                    | fc618310-b936-4247-a5e4-2389a9d8c50e                                                  |
    | mac_address           | fa:16:3e:5e:99:0c                                                                     |
    | name                  |                                                                                       |
    | network_id            | de2df80a-5f69-4630-85ac-4081ce70de98                                                  |
    | security_groups       | 344e5239-44cd-4b14-9cf1-d0c3bd2f27ed                                                  |
    | status                | ACTIVE                                                                                |
    | tenant_id             | ba7a2c788ab849e0a583cf54bec0a1f4                                                      |
    +-----------------------+---------------------------------------------------------------------------------------+
    
    root@node-1:~# neutron subnet-show d75307b5-137f-4fd4-8c30-17974a8489a3
    +-------------------+------------------------------------------------------+
    | Field             | Value                                                |
    +-------------------+------------------------------------------------------+
    | allocation_pools  | {"start": "192.168.111.2", "end": "192.168.111.254"} |
    | cidr              | 192.168.111.0/24                                     |
    | dns_nameservers   | 114.114.114.114                                      |
    |                   | 8.8.8.8                                              |
    | enable_dhcp       | True                                                 |
    | gateway_ip        | 192.168.111.1                                        |
    | host_routes       |                                                      |
    | id                | d75307b5-137f-4fd4-8c30-17974a8489a3                 |
    | ip_version        | 4                                                    |
    | ipv6_address_mode |                                                      |
    | ipv6_ra_mode      |                                                      |
    | name              | net04__subnet                                        |
    | network_id        | de2df80a-5f69-4630-85ac-4081ce70de98                 |
    | subnetpool_id     |                                                      |
    | tenant_id         | ba7a2c788ab849e0a583cf54bec0a1f4                     |
    +-------------------+------------------------------------------------------+


##### 2.4 dump instance xml by virsh

    root@node-4:~# virsh dumpxml instance-00000039
    
    <interface type='bridge'>
      <mac address='fa:16:3e:5e:99:0c'/>
      <source bridge='qbrfc618310-b9'/>
      <target dev='tapfc618310-b9'/>
      <model type='virtio'/>
      <alias name='net0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>

##### 2.5 show linux bridge

    root@node-4:~# brctl show
    bridge name     bridge id               STP enabled     interfaces
    br-aux          8000.e41d2d0f1091       no              bond0
                                                            p_e52381cd-0
    br-fw-admin             8000.3863bb3350c8       no              eth2
    br-mgmt         8000.e41d2d0f1091       no              bond0.101
    br-storage              8000.e41d2d0f1091       no              bond0.103
    
    qbrfc618310-b9          8000.26d598f1427a       no              qvbfc618310-b9
                                                            tapfc618310-b9
    
##### 2.6 show ovs bridge

    root@node-4:~# ovs-vsctl show   
    ea7c0ff3-687a-4e5d-8e0c-787a3bf57206
        Bridge br-int
            fail_mode: secure
            Port "qvofc618310-b9"
                tag: 6
                Interface "qvofc618310-b9"
            Port int-br-prv
                Interface int-br-prv
                    type: patch
                    options: {peer=phy-br-prv}
            Port br-int
                Interface br-int
                    type: internal
        Bridge br-prv
            Port phy-br-prv
                Interface phy-br-prv
                    type: patch
                    options: {peer=int-br-prv}
            Port br-prv
                Interface br-prv
                    type: internal
            Port "p_e52381cd-0"
                Interface "p_e52381cd-0"
                    type: internal
        ovs_version: "2.3.1"

#### 3. create tc rule

**注意**： tc rule 重启Host后会丢失!!!

    linux bridge port = qvbxxxxxxx
    ovs beidge port = qvoxxxxxxx


##### 3.1 create

    # linux bridge limit outgoing bandwidth
    tc qdisc add dev <LinuxBridge Port> root handle 1: htb default 100
    
    tc class add dev <LinuxBridge Port> parent 1: classid 1:100 htb rate <Bandwidth>mbit ceil <Bandwidth*2>mbit burst <Bandwidth*10>mbit
    tc qdisc add dev <LinuxBridge Port> parent 1:100 sfq perturb 10
    
    tc class add dev <LinuxBridge Port> parent 1: classid 1:1 htb rate 10gbit
    tc qdisc add dev <LinuxBridge Port> parent 1:1 sfq perturb 10
    
    tc filter add dev <LinuxBridge Port> protocol ip parent 1: prio 1 u32 match ip dst <Subnet CIDR> flowid 1:1
    
    # ovs bridge limit ingoing bandwidth
    tc qdisc add dev <OVSBridge Port> root handle 1: htb default 100
    
    tc class add dev <OVSBridge Port> parent 1: classid 1:1 htb rate 10gbit
    tc qdisc add dev <OVSBridge Port> parent 1:1 sfq perturb 10
    
    tc class add dev <OVSBridge Port> parent 1: classid 1:100 htb rate <Bandwidth>mbit ceil <Bandwidth*2>mbit burst <Bandwidth*10>mbit
    tc qdisc add dev <OVSBridge Port> parent 1:100 sfq perturb 10

    tc filter add dev <OVSBridge Port> protocol ip parent 1: prio 1 u32 match ip src <Subnet CIDR> flowid 1:1

##### 3.2 update

    tc class change dev <LinuxBridge Port> parent 1: classid 1:100 htb rate <New Bandwidth>mbit ceil <New Bandwidth * 2>mbit burst <New Bandwidth * 10>mbit 
    tc class change dev <OVSBridge Port> parent 1: classid 1:100 htb rate <New Bandwidth>mbit ceil <New Bandwidth * 2>mbit burst <New Bandwidth * 10>mbit 

##### 3.3 delete

    tc qdisc del dev <LinuxBridge Port> root
    tc qdisc del dev <OVSBridge Port> root
    
##### 3.4 show
    
    tc -s qdisc show dev <Port>
    tc -s class show dev <Port>
    tc -s filter show dev <Port>

#### 4. test

    # no bandwidth limit
    100%[============================================================>] 610,271,232 91.3MB/s   in 6.3s
    
    # 5Mbit limit
    
#### 5. listen to openstack notification bus to create tc rule

{% highlight python %}
#!/usr/bin/env python
#-*- coding=utf-8 -*-

# python qos_agent.py > /dev/null 2>&1 &

import datetime
import logging
import requests
import subprocess
from kombu.mixins import ConsumerMixin
from kombu.log import get_logger
from kombu import Queue, Exchange


######  eonboard config  ######
EONBAORD_API_URL = "10.6.13.82:8000"

######  log config  ######
LOG = get_logger(__name__)
LOG.setLevel(logging.INFO)
f_handler = logging.FileHandler('/var/log/nova/qos_agent.log')
f_handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s: %(message)s')
f_handler.setFormatter(formatter)
LOG.addHandler(f_handler)


###### rabbit config ######
HOST = "14.14.15.6"
PORT = 5673
USER = "nova"
PASSWD = "CavteiuV"
CONN_STR = "amqp://%s:%s@%s:%s//" % (USER, PASSWD, HOST, PORT)
TASK_QUEUE = [
    Queue("qos.nova.info",
        Exchange('nova', 'topic', durable=False),
        durable=False, routing_key='notifications.info'),
    Queue("qos.nova.error",
        Exchange('nova', 'topic', durable=False),
        durable=False, routing_key='notifications.error'),

    Queue('qos.neutron.info',
        Exchange('neutron', 'topic', durable=False),
        durable=False, routing_key='notifications.info'),
    Queue('qos.neutron.error',
        Exchange('neutron', 'topic', durable=False),
        durable=False, routing_key='notifications.error'),
]


######  tc template  ######

CLEAN_RULE = ["tc qdisc del dev %(linux_bridge_port)s root",
              "tc qdisc del dev %(ovs_port)s root"]

CREATE_LINUX_BRIDGE_RULE = """
tc qdisc add dev %(linux_bridge_port)s root handle 1: htb default 100
tc class add dev %(linux_bridge_port)s parent 1: classid 1:100 htb rate %(bandwidth)dmbit ceil %(bandwidth_2)dmbit burst %(bandwidth_10)dmbit
tc qdisc add dev %(linux_bridge_port)s parent 1:100 sfq perturb 10
tc class add dev %(linux_bridge_port)s parent 1: classid 1:1 htb rate 10gbit
tc qdisc add dev %(linux_bridge_port)s parent 1:1 sfq perturb 10
tc filter add dev %(linux_bridge_port)s protocol ip parent 1: prio 1 u32 match ip dst %(subnet_cidr)s flowid 1:1
"""

CREATE_OVS_PROT_RULE = """
tc qdisc add dev %(ovs_port)s root handle 1: htb default 100
tc class add dev %(ovs_port)s parent 1: classid 1:1 htb rate 10gbit
tc qdisc add dev %(ovs_port)s parent 1:1 sfq perturb 10
tc class add dev %(ovs_port)s parent 1: classid 1:100 htb rate %(bandwidth)dmbit ceil %(bandwidth_2)dmbit burst %(bandwidth_10)dmbit
tc qdisc add dev %(ovs_port)s parent 1:100 sfq perturb 10
tc filter add dev  %(ovs_port)s protocol ip parent 1: prio 1 u32 match ip src %(subnet_cidr)s flowid 1:1
"""

def get_instance_args_by_payload(payload):
    args = None
    if payload.has_key("instance_id"):
        args = payload["instance_id"]
    if payload.has_key("floatingip"):
        args = payload["floatingip"].get("floating_ip_address", None)
        floating_port = payload["floatingip"].get("port_id", None)
        if not floating_port:
            args = None
    if args:
        resp = requests.get("http://%(eonboard_api_url)s/api/instances/%(args)s/detail/" % {
                        "eonboard_api_url": EONBAORD_API_URL, 'args': args})
        if resp.status_code == 200:
            return  resp.json()

    return None

def make_sure_tc_qos_exist(payload):
    if not payload:
        LOG.info("Create tc rule, but payload is null.")
        return
    
    if type(payload) == type(list):
        payload = payload[0]
    instance = get_instance_args_by_payload(payload)
    if not instance:
        LOG.info("get instance by payload is None. payload:[%s]", payload)
        return
    port_11 = instance["port"][0:11]
    prepare_args = {"linux_bridge_port": "qvb%s" % port_11,
                  "ovs_port": "qvo%s" % port_11,
                  "subnet_cidr": instance["network_info"]["address"],
                  "bandwidth": instance["bandwidth"]*1,
                  "bandwidth_2": instance["bandwidth"]*2,
                  "bandwidth_10": instance["bandwidth"]*10,
                }

    linux_bridge_port_rule = CREATE_LINUX_BRIDGE_RULE % prepare_args
    ovs_bridge_port_rule =  CREATE_OVS_PROT_RULE  % prepare_args

    #print linux_bridge_port_rule
    #print ovs_bridge_port_rule

    cmd_list = []
    for cmd in linux_bridge_port_rule.split("\n"):
        if len(cmd) > 0:
            cmd_list.append(cmd)
    
    for cmd in ovs_bridge_port_rule.split("\n"):
        if len(cmd) > 0:
            cmd_list.append(cmd)

    for cmd in CLEAN_RULE: 
        cmd = cmd % prepare_args
        try:
            ret = subprocess.call(['ssh', instance["host"], cmd])
        except:
            pass

    ret = subprocess.call(['ssh', instance["host"], " && ".join(cmd_list)])
    if ret == 0:
        LOG.info("[Instance:%s] qos execute succeed. \ncmd: %s", instance['uuid'], cmd_list)
    else:
        LOG.error("[Instance:%s] cmd: %s", instance.uuid, cmd_list)
        LOG.error("[Instance:%s] qos execute failed.", instance['uuid'])
     

MESSAGE_PROCESS = {
    "compute.instance.create.end": make_sure_tc_qos_exist,
    "compute.instance.power_on.end": make_sure_tc_qos_exist,
    "floatingip.update.end": make_sure_tc_qos_exist,
}


class Worker(ConsumerMixin):
    
    def __init__(self, connection):
        self.connection = connection

    def get_consumers(self, Consumer, channel):
        return [Consumer(queues=TASK_QUEUE,
                         accept=['json'],
                         callbacks=[self.process_message])]

    def process_message(self, body, message):
        try:
            event_type = body.get('event_type', None)
            if event_type in MESSAGE_PROCESS.keys():
                MESSAGE_PROCESS[event_type](body.get('payload', None))
            else:
                LOG.warn("Ingnore event_type [%s]", event_type)
        except Exception as e:
            LOG.exception("Process message exception")
        message.ack()


if __name__ == '__main__':
    from kombu import Connection
    from kombu.utils.debug import setup_logging
    setup_logging(loglevel='DEBUG', loggers=[''])
    LOG.info(CONN_STR)
    with Connection(CONN_STR) as conn:
        try:
            LOG.info("#################GO###################")
            worker = Worker(conn)
            worker.run()
        except KeyboardInterrupt:
            LOG.info('bye bye')
{% endhighlight%}
