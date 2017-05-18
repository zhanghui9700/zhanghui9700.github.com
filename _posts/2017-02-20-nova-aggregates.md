---
layout: post
category: openstack
title: hands on nova aggregates
tags: [linux, openstack]

---


###  aggregates

>测试版本：Fuel(9.0.0) openstack(Mitaka)

#### what's aggregates in nova
Aggregates是在 OpenStack 的 Regions 和 Availability Zones 之后被提出来，并建立于 Availability Zones 基础之上更进一步划分 computes 节点物理资源的一种机制。

Availability Zones 通常是对 computes 节点上的资源在小的区域内进行逻辑上的分组和隔离。例如在同一个数据中心，我们可以将 Availability Zones 规划到不同的机房，或者在同一机房的几个相邻的机架，从而保障如果某个 Availability Zone 的节点发生故障（如供电系统或网络），而不影响其他的 Availability Zones 上节点运行的虚拟机，通过这种划分来提高 OpenStack 的可用性。目前 OpenStack 默认的安装是把所有的 computes 节点划分到 nova 的 Availability Zone 上。

Host Aggregates 是在 Availability Zones 的基础上更进一步地进行逻辑的分组和隔离。例如我们可以根据不同的 computes 节点的物理硬件配置将具有相同共性的物理资源规划在同一 Host Aggregate 之下，或者根据用户的具体需求将几个 computes 节点规划在具有相同用途的同一 Host Aggregate 之下，通过这样的划分有利于提高 OpenStack 资源的使用效率。使用场景如下：

1. 在具有相同物理特性的 computes 节点上创建 Host Aggregate, 比如下面将具有高性能CPU的 computes 节点规划为一组，并将 Host Aggregate 命名为“cpu/xeon-e7”。
1. 覆盖nova.conf的配置， eg：ram_allocation_ratio/AggregateRamFilter

![img](http://images.cnitblog.com/i/519867/201403/312156452359349.png)
![img](http://img.blog.csdn.net/20141214143337168)
![img](https://www.ibm.com/developerworks/cn/cloud/library/1604-openstack-host-aggregate/img001.png)

az对用户是可见的，aggregates只对程序可见，由nova-scheduler使用。

查看nova源码下的ls scheduler/filters

    affinity_filter.py
    aggregate_image_properties_isolation.py
    aggregate_instance_extra_specs.py
    aggregate_multitenancy_isolation.py
    all_hosts_filter.py
    availability_zone_filter.py
    compute_capabilities_filter.py
    compute_filter.py
    core_filter.py
    disk_filter.py
    exact_core_filter.py
    exact_disk_filter.py
    exact_ram_filter.py
    extra_specs_ops.py
    image_props_filter.py
    io_ops_filter.py
    isolated_hosts_filter.py
    json_filter.py
    metrics_filter.py
    numa_topology_filter.py
    num_instances_filter.py
    pci_passthrough_filter.py
    ram_filter.py
    retry_filter.py
    trusted_filter.py
    type_filter.py

`nova help | grep 'aggregate`

    aggregate-add-host          Add the host to the specified aggregate.
    aggregate-create            Create a new aggregate with the specified
    aggregate-delete            Delete the aggregate.
    aggregate-details           Show details of the specified aggregate.
    aggregate-list              Print a list of all aggregates.
    aggregate-remove-host       Remove the specified host from the specified
                                aggregate.
    aggregate-set-metadata      Update the metadata associated with the
                                aggregate.
    aggregate-update            Update the aggregate's name and optionally

`nova help aggregate-create`

    usage: nova aggregate-create <name> [<availability-zone>]
    
    Create a new aggregate with the specified details.
    
    Positional arguments:
      <name>               Name of aggregate.
      <availability-zone>  The availability zone of the aggregate (optional).


#### 新建一个aggregate

`root@node-6:~# nova availability-zone-list    `
`root@node-6:~# nova service-list`

    +----+------------------+--------------------+----------+---------+-------+----------------------------+-----------------+
    | Id | Binary           | Host               | Zone     | Status  | State | Updated_at                 | Disabled Reason |
    +----+------------------+--------------------+----------+---------+-------+----------------------------+-----------------+
    | 8  | nova-compute     | node-4.suninfo.com | nova     | enabled | up    | 2017-02-15T03:10:51.000000 | -               |
    +----+------------------+--------------------+----------+---------+-------+----------------------------+-----------------+

`root@node-6:~# nova aggregate-create cpu/xeon-e7 nova`
>如果没有指定 Availability Zone, OpenStack 会将 Host Aggregate 建在默认的 Availability Zone 下面（如 nova），否则会根据指定的名字来判断是否创建新的 Availability Zone 或使用已经存在的 Availability Zone，同时在此之下创建 Host Aggregate。

    +----+-------------+-------------------+-------+--------------------------+
    | Id | Name        | Availability Zone | Hosts | Metadata                 |
    +----+-------------+-------------------+-------+--------------------------+
    | 12 | cpu/xeon-e7 | nova              |       | 'availability_zone=nova' |
    +----+-------------+-------------------+-------+--------------------------+
    
`root@node-6:~# nova hypervisor-list`

    +----+---------------------+-------+---------+
    | ID | Hypervisor hostname | State | Status  |
    +----+---------------------+-------+---------+
    | 1  | node-4.suninfo.com  | up    | enabled |
    +----+---------------------+-------+---------+

`root@node-6:~# nova aggregate-add-host cpu/xeon-e7 node-4.suninfo.com`

    Host node-4.suninfo.com has been successfully added for aggregate 12 
    +----+-------------+-------------------+----------------------+--------------------------+
    | Id | Name        | Availability Zone | Hosts                | Metadata                 |
    +----+-------------+-------------------+----------------------+--------------------------+
    | 12 | cpu/xeon-e7 | nova              | 'node-4.suninfo.com' | 'availability_zone=nova' |
    +----+-------------+-------------------+----------------------+--------------------------+

>启动vm并指定计算节点，只需要az功能即可实现, az对用户是可见的。如果希望做一些调度优化，那么就需要管理员通过aggregates来实现。
`root@node-6:~# nova boot  --image 027e7611-c85f-4097-8d66-eab63f620987 --flavor m1.micro --nic net-id=a18d722f-1edf-4e17-a86d-a96c45fcaaaf --availability-zone nova:node-4.suninfo.com  az-test-vm`

#### 确认添加AggregateInstanceExtraSpecsFilter到nova.conf的scheduler_default_filters

#### 整合aggregates和flavor， 选择flavor后自动调度到相应的aggregates　meta匹配的计算节点

`root@node-6:~# nova aggregate-set-metadata cpu/xeon-e7 cpu=xeon-e7`

    Metadata has been successfully updated for aggregate 12.
    +----+-------------+-------------------+----------------------+-----------------------------------------+
    | Id | Name        | Availability Zone | Hosts                | Metadata                                |
    +----+-------------+-------------------+----------------------+-----------------------------------------+
    | 12 | cpu/xeon-e7 | nova              | 'node-4.suninfo.com' | 'cpu=xeon-e7', 'availability_zone=nova' |
    +----+-------------+-------------------+----------------------+-----------------------------------------+

`root@node-6:~# nova flavor-create cpu.xeon-e7 auto 4096 10 2`

`root@node-6:~# nova flavor-key cpu.xeon-e7 set aggregate_instance_extra_specs:cpu=xeon-e7`

    +----------------------------+--------------------------------------+
    | Property                   | Value                                |
    +----------------------------+--------------------------------------+
    | OS-FLV-DISABLED:disabled   | False                                |
    | OS-FLV-EXT-DATA:ephemeral  | 0                                    |
    | disk                       | 10                                   |
    | extra_specs                | {"aggregate_instance_extra_specs:cpu": "xeon-e7"}              |
    | id                         | 11224306-e4df-483b-9a1f-5c35c47a5584 |
    | name                       | cpu.xeon-e7                          |
    | os-flavor-access:is_public | True                                 |
    | ram                        | 4096                                 |
    | rxtx_factor                | 1.0                                  |
    | swap                       |                                      |
    | vcpus                      | 2                                    |
    +----------------------------+--------------------------------------+


再创建一个测试用的flavor，规格相同，extra_specs不同

`root@node-6:~# nova flavor-create cpu.xeon-e5 auto 4096 10 2`
`root@node-6:~# nova flavor-key cpu.xeon-e5 set aggregate_instance_extra_specs:cpu=xeon-e5`

测试，通过flavor启动vm

`nova boot  --image 027e7611-c85f-4097-8d66-eab63f620987 --flavor cpu.xeon-e5 --nic net-id=a18d722f-1edf-4e17-a86d-a96c45fcaaaf   aggregate-test-vm`

    | 5048dbaf-6d24-4c46-a496-2d670dbb59c8 | aggregate-test-vm | ERROR  | -          | NOSTATE     |                                                   |

`nova boot  --image 027e7611-c85f-4097-8d66-eab63f620987 --flavor cpu.xeon-e7 --nic net-id=a18d722f-1edf-4e17-a86d-a96c45fcaaaf   aggregate-test-vm`

    | 056dba3d-b3a3-409e-a193-35506981c0ef | aggregate-test-vm | ACTIVE | -          | Running     | admin_internal_net=192.168.111.121                |

> flavor cpu.xeon-e5的vm创建失败，flavor cpu.xeon-e7的vm创建成功，aggregate生效。

#### warning

`root@node-6:~# nova aggregate-add-host cpu/xeon-e5 node-4.suninfo.com`

>ERROR (Conflict): Cannot add host to aggregate 12. Reason: One or more hosts already in availability zone(s) [u'nova']. (HTTP 409) (Request-ID: req-81aa55b5-0bb2-47e1-89c2-4d64ac9c9a8c)

一个nova-compute节点只能在一个az内，但是可以存在多个aggregate内。

`ComputeCapabilitiesFilter`也会使用flavor的extra-specs去和host-state的属性做对比，所以flavor的extra-spece key需要根据一定的规则跳过ComputeCapabilitiesFilter的检查， key名称用此格式"TYPE:KEY",  type只要不等于"capabilities"即可跳过

`AggregateInstanceExtraSpecsFilter`的metadata key也需要一些规则约束，key名称使用格式flavor extra-specs中的"aggregate_instance_extra_specs:KEY"中的KEY部分  

一个计算节点属于多个aggregate,并且具有相同的metadata key，那么这个host的key对应的值为set集合，匹配规则为任一个满足即可。

#### ATTENTION

1. Resize/Migrate时都需要重新scheduler,所以需要避免在高性能物理服务器上的vm调度到普通机器上。  
1. ComputeCapabilitiesFilter在N版本之前存在bug（#1582589），最好禁用，否则只能用特殊的flavor.metadata key(上面有key格式说明)。N版本已经Fix此bug

REFERENCES:  
[host-aggregate](https://www.ibm.com/developerworks/cn/cloud/library/1604-openstack-host-aggregate/)

