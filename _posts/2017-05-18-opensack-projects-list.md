---
layout: post
category: openstack
title: OpenStack Projects Overview
tags: [linux, openstack]

---

### Openstack Service Projects(Ocata)
>https://releases.openstack.org/ocata/index.html

#### `aodh  `
> ceilometer alarming  
[github](https://github.com/openstack/aodh)  
[see: aodh](http://www.cnblogs.com/knitmesh/p/5464709.html)

#### `barbican `
>Barbican 是 OpenStack 的key管理组件，定位在提供 REST API 来安全存储、提供和管理“秘密”。  
![architecture](http://img.blog.csdn.net/20160513151040730)  
[see: what is barbican](http://blog.csdn.net/u010774286/article/details/50384786)

#### `ceilometer  `  
>Ceilometer是OpenStack中的一个子项目，它像一个漏斗一样，能把OpenStack内部发生 的几乎所有的事件都收集起来，然后为计费和监控以及其它服务提供数据支撑。ceilometer被一分为四（Ceilometer、Gnocchi、Aodh、Panko），各司其职！其中Ceilometer负责采集计量数据并加工预处理；Gnocchi主要用来提供资源索引和存储时序计量数据；Aodh主要提供预警和计量通知服务；Panko主要提供事件存储服务。  
![architecture](https://www.ustack.com/wp-content/uploads/2013/08/ceilometer-architecture.png)
[gnocchi](http://blog.sina.com.cn/s/blog_6de3aa8a0102wk0y.html)

#### `cinder  `  
> block storage management

#### `cloudkitty  `  
> billing?

#### `congress        `  
>策略即服务?  Congress 是云端开放的策略框架。云的操作者可以通过 Congress 在异构云环境中申报、监测、执行和审计“策略”。Congress 从云端不同的云服务中获取输入；例如在 OpenStack 中，Congress 从 Nova、Neutron 的网络状态中获取 VMs 信息。然后 Congress 会把这些输入数据从这些服务中输入到策略引擎当中，在那里 Congress 可以通过云运营商的政策来验证云端实际的状态。  
>Congress是一个基于异构云环境的策略声明、监控、实施、审计的框架（policy-as-a-service）。Congress从云中不同的服务获取数据，输入到congress的策略引擎，从而验证云中的各服务状态是否按照设置的策略运行。

#### `designate `  
>Designate提供了DNSaaS（DNS即服务）的功能，其目标就是要赋予OpenStack提供这种云域名系统的能力，云服务商可以使用Designate就能够很容易建造一个云域名管理系统来托管租户的公有域名。  
![architecutre](http://img.blog.csdn.net/20150527213621356)
[see: what is designate](http://blog.csdn.net/andyron/article/details/46053241)

#### `freezer   `
>Freezer是一套开源的备份软件，它能帮助你自动的进行数据备份和还原动作。目前Freezer已正式引入OpenStack，从事数据备份，是OpenStack社区中一个官方项目，旨在为OpenStack提供数据备份环境的解决方案。  
[see: OpenStack云环境数据备份解决方案解析](http://www.99cloud.net/html/2016/jiuzhouyuanchuang_0818/213.html)

#### `glance `
> Image management

#### `heat        `
> OrchestrationService  
Stack（栈）： 在Heat领域，Stack是多个由Heat创建的对象或者资源的集合。它包含实例（虚拟机），网络，子网，路由，端口，路由端口，安全组（Security Group）,安全组规则，自动伸缩等。  
Template（模板）: Heat使用template的概念来定义一个Stack. 如果你想要一个由私有网连接的2个实例，那么你的template需要包括2个实例，一个网络，一个子网和2个网络端口的定义。既然template是Heat工作的中心点，本文在后面将会展示一些例子。  
Parameters(参数)：Heat template有三个部分，而其中的一个就是要定义template的参数。参数包含一些基本信息，比如具体的镜像ID，或者特定网络ID。他们将由用户输入给template. 这种参数机制允许用户创建一个一般的template，它可能潜在使用不同的具体资源。  
Resources(资源)：Resource就是由Heat创建或者修改的具体的资源。它是Heat template的第二个重要部分。  
Output(输出)：Heat template的第三个和最后一个重要部分就是Output(输出)。它是通过OpenStack Dashboard或者Heat stack-list/stack-show命令来显示给用户。  
HOT: Heat Orchestration Template的缩写，是Heat template使用的两种格式的一种。HOT并不与AWS CloudFormation template格式兼容，只能被OpenStack使用。HOT格式的template，通常但不是必须使用YAML。  
CFN：AWS CloudFormation的缩写，Heat支持的第二种格式。CFN格式的template通常使用JSON。  

#### `horizon    `
> web ui

#### `ironic `
> baremetal management

#### `keystone`    
> auth

#### `magnum  `
>Magnum 利用 Keystone, Nova, Heat, Neutron 等已有的 OpenStack组件，整合容器的 集群管理系统如 kubernetes, Mesos 等, 为用户更加简单灵活，多租户的容器服务  
![architecture](http://7xnzbp.com1.z0.glb.clouddn.com/wp-content%2Fuploads%2F2016%2F05%2F800px-Magnum_architecture.png)
![deployment](http://7xnzbp.com1.z0.glb.clouddn.com/wp-content%2Fuploads%2F2016%2F05%2FDeployment.png)
[architecture](http://www.sdnlab.com/16932.html)  
[tutorial](http://mathslinux.org/?p=849#org40f8fa7)  

#### `manila  `
>Manila项目全称是File Share Service，文件共享即服务。是OpenStack大帐篷模式下的子项目之一，用来提供云上的文件共享，支持CIFS协议和NFS协议。   
1. 创建一个Nova实例，通过Cinder的Volume来提供NFS/CIFS共享服务  
1. 每个Share Network创建一个Nova实例  
1. 连接到已存在Neutron网络及子网中  
1. 创建Nova实例使用的Nova的flavor、Glance的image、SSH Keypair均是Manila配置的  
1. Manila通过 SSH对Nova实例进行配置  
![workflow](http://s2.51cto.com/wyfs02/M01/7C/9E/wKiom1bTvmiju4ZlAAB2I43IlVg774.jpg)  
[tutorail](http://sangh.blog.51cto.com/6892345/1745955)

#### `mistral  `   
>Mistral是mirantis公司为openstack开发的工作流组件，提供WorkFlow as a service。 典型的用户用例包括云平台的任务计划服务（Cloud Cron），任务调度（Task Scheduling）， 复杂的运行时间长的业务流程服务。目前项目还在开始阶段。对应的是AWS的SWS（Simple WorkFlow Service）。  
[see: introduction](https://my.oschina.net/crook/blog/221114)

#### `monasca-api ` 
#### `monasca-log-api`
>monasca一个具有高性能，可扩展，高可用的监控即服务的（MONaas）解决方案。
使用Rest API接口来存储、查询性能和历史数据，不同与其他监控工具使用特殊的协议和传输方法，如nagios的NSCA，Monasca只利用了http。  
多租户认证，指标的提交和认证使用Keystone组件。存储关联租户ID  
指标使用（key，value）的键值来定义，称作量度（dimensions）  
对系统指标进行实时阈值和告警  
复合告警设置使用简单的语法，由子告警表达式和逻辑操作器组成  
监控代理支持内置的系统和服务的检查结果，同时也只nagios的checks和statsd  
根据开源技术搭建的开源监控方案  
![architecture](http://p1.bqimg.com/567571/fe84bd5e5312afe0.png)  
[see: introduction](http://qujunorz.blog.51cto.com/6378776/1868286)

#### `murano  `
>Murano是OpenStack的Application Catalog服务，推崇AaaS(Anything-as-a-Service)的概念，通过统一的框架和API实现应用程序快速部署和,用程序生命周期管理的功能，降低应用程序对底层平台(OpenStack层和虚拟化层)的依赖。
[see: introduction](http://blog.csdn.net/ustc_dylan/article/details/46333225)  
[see: introduction](http://www.99cloud.net/html/2016/jiuzhouyuanchuang_0625/180.html)

#### `neutron  `    
> network management

#### `nova `
> compute management, kvm/xen/esxi

#### `panko `  
>Panko is designed to provide a metadata indexing, event storage service which enables users to capture the state information of OpenStack resources at a given time. Its aim is to enable a scalable means of storing both short and long term data for use cases such as auditing and system debugging.

#### `sahara ` 
>Sahara项目的目标是使用户能够在Openstack平台上一键式创建和管理Hadoop集群，实现类似AWS的EMR（Amazon Elastic MapReduce service）功能。用户只需要提供简单的配置参数和模板，如版本信息(如CDH版本）、集群拓扑（几个Slave，几个datanode）、节点配置信息（CPU、内存）等，Sahara服务就能够在几分钟时间内根据提供的模板快速部署Hadoop、Spark以及Storm集群。Sahara目支持节点的动态扩展（scalable），几乎所有插件支持扩容操作，部分插件还支持缩容，能够方便地按需增加或者减少节点数量，实现弹性大数据计算服务，适合开发人员或者QA在Openstack平台上快速部署大数据处理平台。   
![compents](http://int32bit.me/img/posts/Openstack%E5%A4%A7%E6%95%B0%E6%8D%AESahara%E9%A1%B9%E7%9B%AE%E5%AE%9E%E8%B7%B5/sahara-arch.png)
![architecture](http://int32bit.me/img/posts/Openstack%E5%A4%A7%E6%95%B0%E6%8D%AESahara%E9%A1%B9%E7%9B%AE%E5%AE%9E%E8%B7%B5/sahara.png)  
[see: introduction](http://int32bit.me/2016/07/27/Openstack%E5%A4%A7%E6%95%B0%E6%8D%AE%E9%A1%B9%E7%9B%AESahara%E5%AE%9E%E8%B7%B5%E6%80%BB%E7%BB%93/#sahara-2)

#### `searchlight`         
>Searchlight dramatically improves the user focused search capabilities and performance on behalf of various OpenStack cloud services.  
![concept overview](https://wiki.openstack.org/w/images/a/ae/Searchlight-Concept-1.png)  
[see: introduction](https://www.slideshare.net/openstack/searchlight-updates-liberty-edition)

#### `senlin  `
>Senlin是专为管理其他OpenStack服务中同类对象而设计的集群服务。它的特点在于拥有一个开放的框架，开发者能够为指定类型的对象提供插件以实现托管，以及在特定集群运行时想执行的策略。简而言之，它们能够为编程/管理OpenStack云提供一个阵列数据类型。  
1.    自动扩容  
Senlin有针对性的实现了跨可用Zone的部署、跨Region的部署、指定节点删除、手动扩容等功能。  
2.    负载均衡  
根据负载均衡policy，可以实现lb member的自动增加或者减少。  
3.    虚拟机HA  
虚拟机HA是一个企业级的功能，senlin会检测Node（虚拟机）的状态，当这个节点宕机时，会启用相关的recovery策略。  
4.    在Magnum中用来管理容器  
Senlin增加对Container的支持后在Magnum中就有了用武之地。东京峰会上腾对此有专题演讲：《Exploring Magnum and Senlin Integration for AutoScaling containers》  
5.    在Sahara中管理Handoop集群  
基于Ironic实现物理机的部署与管理。  
[see: introduction](http://www.99cloud.net/html/2016/jiuzhouyuanchuang_0920/226.html)

#### `solum   `
>Solum是由Rackspace的工程师Adrian Otto于2013年9月在Launchpad上提出的一个BP。该项目聚焦于在OpenStack IaaS平台上，构建PaaS层的持续集成/持续交付（CI/CD）应用，可以简单理解为是一个应用程序App的集成开发平台。
![components](https://wiki.openstack.org/w/images/d/de/Solum-with-other-services.jpg)
[see: introduction](http://www.10tiao.com/html/594/201701/2649839518/1.html)

#### `swift   `
> object storage

#### `tacker  `
>Tacker是一个在OpenStack内部孵化的项目, 他的作用是NVF管理器，用于管理NVF的生命周期。 Tacker的重点是配置VNF, 并监视他们。如果需要，还可重启和/或扩展（自动修复）NVF。整个进程贯穿ETSIMANO所描述的整个生命周期。  
![architecture](http://img2016.itdadao.com/d/file/tech/2016/11/14/it393540141558173.jpg)  
![workflow](http://img2016.itdadao.com/d/file/tech/2016/11/14/it393540141558174.jpg)  
[see: introduction](http://www.itdadao.com/articles/c15a745945p0.html)  

#### `tricircle`   
>Tricircle is dedicated for networking automation across Neutron in multi-region OpenStack deployments. From the control plane view (cloud management view ), Tricircle is to make Neutron(s) in multi-region OpenStack clouds working as one cluster, and enable the creation of global network/router etc abstract networking resources across multiple OpenStack clouds. From the data plane view (end user resources view), all VMs(also could be bare metal servers or containers) are provisioned in different cloud but can be inter-connected via the global abstract networking resources, of course, with tenant level isolation.  
![introduction](https://wiki.openstack.org/w/images/thumb/b/b1/Tricircle_view.png/577px-Tricircle_view.png)

#### `trove   `
>对比Amazon AWS中各种关于数据的服务，其中最著名的是RDS（SQL-base）和DynamoDB（NoSQL），除了实现了基本的数据管理能力，还具备良好的伸缩能力、容灾能力和不同规格的性能表现。因此，对于最炙手可热的开源云计算平台Openstack来说，也从Icehouse版加入了DBaaS服务，代号Trove。“Trove is Database as a Service for OpenStack. It’s designed to run entirely on OpenStack, with the goal of allowing users to quickly and easily utilize the features of a relational or non-relational database without the burden of handling complex administrative tasks. ”  
1、动态resize能力  
分为instance-resize和volume-resize，前者主要是实例运行的内存大小和cpu核数，后者主要是指数据库分区对应的硬盘卷的大小。由于实例是跑在vm上的，而vm的cpu和memory的规格可以通过Nova来进行动态调整，所以调整是非常方便快捷的。另外硬盘卷也是由Cinder提供的动态扩展功能来实现resize。resize过程中服务会有短暂的中断，是由于mysqld重启导致的。  
2、全量与增量备份  
目前mysql的实现中，备份是由实例vm上的guestagent运行xtrabackup工具进行备份，且备份后的文件会存储在Swift对象存储中。从备份创建实例的过程则相反。由于xtrabackup强大的备份功能，所以Trove要做的只是做一些粘胶水的工作。  
3、动态配置更新  
目前支持实例的自定义配置，可以创建配置组应该到一组实例上，且动态attach到运行中的实例中生效。  
4、一主多从的一键创建  
在创建数据库实例的API中，支持批量创建多个从实例，并以指定的实例做主进行同步复制。这样就方便了从一个已有实例创建多个从实例的操作。而且mysql5.6版本之后的同步复制支持GTID二进制日志，使得主从实例之间关系的建立更加可靠和灵活，在failover处理上也更加快速。  
5、集群创建与管理（percona/mariadb支持）  
Cluster功能目前在mysql原生版本暂时不支持，但是其两个分支版本percona和mariadb基于Galera库实现的集群复制技术是支持的。另外Liberty版本的Trove也提供了对mongodb的集群支持。  
![architecture](http://img.blog.csdn.net/20160403012207255)  
![use case](http://img.blog.csdn.net/20160403012305130)  
[see: introduction](http://geek.csdn.net/news/detail/65291)

#### `vitrage  `   
>Vitrage is the Openstack RCA (Root Cause Analysis) Engine for organizing, analyzing and expanding OpenStack alarms & events, yielding insights regarding the root cause of problems and deducing the existence of problems before they are directly detected.  
[see: introduction](https://wiki.openstack.org/wiki/Vitrage)

#### `watcher   `      
>Watcher为OS提供资源优化。主要是通过虚拟机迁移来提高整个数据中心的运营效率，降低TCO。
![watcher](http://images2015.cnblogs.com/blog/822840/201511/822840-20151126090003296-451514647.jpg)  
[see: policy](https://docs.google.com/presentation/d/1sR-k3KdgEMHzpKyvUF7hhkoITe0JDWSd_C6fU0NAby4/edit#slide=id.gca3d12c11_2_52)  
[see: what is watcher](http://www.cnblogs.com/allcloud/p/4996656.html)

#### `zaqar`
>Zaqar is a multi-tenant cloud messaging and notification service for web and mobile developers.