---
layout: post
title: openstack resource tracker and scheduler
category: openstack
tag: [openstack, python]
---



同事最近把jenkins里的openstack的压力测试跑起来了，压力测试的方案使用openstack项目中的[tempest](https://github.com/openstack/tempest)，
24\*7循环跑testcase，早晨同事发现很多VMs状态是Error，看了一下nova-sechduler，因为资源不够导致没有host可用，因此得出一个结论：openstack存在资源泄露。
我们现在就要一起来探索一下openstack的资源调度和监控机制，找到问题解决疑惑，并且需要确认是否真的泄露。

首先看两段log，/var/log/nova/nova-compute.log和/var/log/nova/nova-scheduler.log。

>`/var/log/nova/nova-compute.log (host: trystack-compute3)`
>`nova.compute.resource_tracker [-] Hypervisor: free ram (MB): 23353 `
>`nova.compute.resource_tracker [-] Hypervisor: free disk (GB): 4271`
>`nova.compute.resource_tracker [-] Hypervisor: free VCPUs: -43 `
>`nova.compute.resource_tracker [-] Free ram (MB): -46683`
>`nova.compute.resource_tracker [-] Free disk (GB): -7332`
>`nova.compute.resource_tracker [-] Free VCPUS: -90`
>`nova.compute.resource_tracker [-] Compute_service record updated for trystack-compute3`

>`/var/log/nova/nova-scheduler.log (host: trystack-manager)`
>`nova.openstack.common.rpc.amqp [-] received method 'update_service_capabilities'`
>`nova.scheduler.host_manager [-] Received compute service update from trystack-compute2.`
>`nova.scheduler.host_manager [-] Received compute service update from trystack-compute2.`
>`nova.scheduler.host_manager [-] Received compute service update from trystack-compute2.`

openstack的资源监控机制是每个host自己负责将自己的资源使用情况实时的持久化到数据库里，启动VM的时候需要通过资源调度将VM路由到资源最合理的host上去，那么nova-compute与nova-scheduler是怎么交互的呢？nova-scheduler又是怎么获取每个host上的资源情况呢？

#### update available resource
首先看看nova-compute的update_available_resource这个定时任务(default:60S)，我们看看他做了些什么事情。
1. 定时执行update_available_resouce, 这是compute/resouce_tracker.py: ResouceTracker的一个方法
1. resource_tracker.update_available_resource的逻辑：
    + resource = libvirt_dirver.get_available_resource() 这个资源都是host的真实资源情况，还不包含instance中flavor的资源占用情况。
    + nova-compute log 打印Hypervisor资源相关的信息
    + purge_expired_claims这里我没仔细看
    + 获取当前host上所有未删除的云主机
    + 对resource进行资源扣除根据每个instance的flavor信息mem/disk
    + 持久化resource信息到mysql

#### report driver status
再来看一个和nova-scheduler相关的_report_driver_status(60S)，我们再看看他做了些什么事情。
1. 检查时间间隔
1. capabilities = libvirt_driver.get_host_stats (host的真实资源情况和一些系统参数)
1. update self.last_capabilities = capabilities
1. 另外一个periodic task发生，把capabilities的信息发送给nova-scheduler
1. nova-scheduler服务接受这个rpc call之后cache住这个host的信息
1. 当启动VM的时候nova-scheduler获取到所有的cached的host capabilities，并且通过mysql里的compute_node信息更新capabilities信息。
1. 到此nova-scheduler终于和update_available_resource有了联系。

总起来说，这个逻辑真复杂，为什么不直接用mysql多加了一个rpc call意义在哪？最后还是要依赖于db里的compute_node信息?

{% highlight python%}
    #/nova/compute/manager.py: ComputeManager --> SchedulerDependentManager
    @manager.periodic_task
    def _report_driver_status(self, context):
        curr_time = time.time()
        if curr_time - self._last_host_check > FLAGS.host_state_interval:
            self._last_host_check = curr_time
            LOG.info(_("Updating host status"))
            # This will grab info about the host and queue it
            # to be sent to the Schedulers.
            capabilities = self.driver.get_host_stats(refresh=True)
            capabilities['host_ip'] = FLAGS.my_ip
            self.update_service_capabilities(capabilities)

    #/nova/manager.py: SchedulerDependentManager
    @periodic_task
    def _publish_service_capabilities(self, context):
        """Pass data back to the scheduler at a periodic interval."""
        if self.last_capabilities:
            LOG.debug(_('Notifying Schedulers of capabilities ...'))
            self.scheduler_rpcapi.update_service_capabilities(context,
                    self.service_name, self.host, self.last_capabilities)

    #/nova/schedule/host_manager.py: HostManager
    def update_service_capabilities(self, service_name, host, capabilities):
        """Update the per-service capabilities based on this notification."""
        LOG.debug(_("Received %(service_name)s service update from "
                    "%(host)s.") % locals())
        service_caps = self.service_states.get(host, {})
        # Copy the capabilities, so we don't modify the original dict
        capab_copy = dict(capabilities)
        capab_copy["timestamp"] = timeutils.utcnow()  # Reported time
        service_caps[service_name] = capab_copy
        self.service_states[host] = service_caps

    def get_all_host_states(self, context, topic):
        """Returns a dict of all the hosts the HostManager
        knows about. Also, each of the consumable resources in HostState
        are pre-populated and adjusted based on data in the db.

        For example:
        {'192.168.1.100': HostState(), ...}

        Note: this can be very slow with a lot of instances.
        InstanceType table isn't required since a copy is stored
        with the instance (in case the InstanceType changed since the
        instance was created)."""

        if topic != 'compute':
            raise NotImplementedError(_(
                "host_manager only implemented for 'compute'"))

        # Get resource usage across the available compute nodes:
        compute_nodes = db.compute_node_get_all(context)
        for compute in compute_nodes:
            service = compute['service']
            if not service:
                LOG.warn(_("No service for compute ID %s") % compute['id'])
                continue
            host = service['host']
            capabilities = self.service_states.get(host, None)
            host_state = self.host_state_map.get(host)
            if host_state:
                host_state.update_capabilities(topic, capabilities,
                                               dict(service.iteritems()))
            else:
                host_state = self.host_state_cls(host, topic,
                        capabilities=capabilities,
                        service=dict(service.iteritems()))
                self.host_state_map[host] = host_state
            host_state.update_from_compute_node(compute)

        return self.host_state_map
{% endhighlight%}

{% highlight python %}
#/nova/compute/manager.py:ComputeManager
@manager.periodic_task
def update_available_resource(self, context):
    #self.resource_tracker = resource_tracker.ResourceTracker(host, driver)
    self.resource_tracker.update_available_resource(context)

#/nova/compute/resource_tracker.py:ResourceTracker
@utils.synchronized(COMPUTE_RESOURCE_SEMAPHORE)
def update_available_resource(self, context):
    resources = self.driver.get_available_resource()
    #self._verify_resources(resources)
    #self._report_hypervisor_resource_view(resources)
    self._purge_expired_claims()
    instances = db.instance_get_all_by_host(context, self.host)
    self._update_usage_from_instances(resources, instances)
    #self._report_final_resource_view(resources)
    self._sync_compute_node(context, resources)

def _sync_compute_node(self, context, resources):
        """Create or update the compute node DB record"""
        def _get_service(self, context):
            try:
                return db.service_get_all_compute_by_host(context,
                        self.host)[0]
            except exception.NotFound:
                LOG.warn(_("No service record for host %s"), self.host)

        if not self.compute_node:
            # we need a copy of the ComputeNode record:
            service = self._get_service(context)
            if not service:
                # no service record, disable resource
                return

            compute_node_ref = service['compute_node']
            if compute_node_ref:
                self.compute_node = compute_node_ref[0]

        def _create(self, context, values):
            """Create the compute node in the DB"""
            # initialize load stats from existing instances:
            compute_node = db.compute_node_create(context, values)
            self.compute_node = dict(compute_node)

        def _update(self, context, values, prune_stats=False):
            """Persist the compute node updates to the DB"""
            compute_node = db.compute_node_update(context,
                    self.compute_node['id'], values, prune_stats)
            self.compute_node = dict(compute_node)

        if not self.compute_node:
            resources['service_id'] = service['id']
            self._create(context, resources)
            LOG.info(_('Compute_service record created for %s ') % self.host)
        else:
            self._update(context, resources, prune_stats=True)
            LOG.info(_('Compute_service record updated for %s ') % self.host)


def _update_usage_from_instances(self, resources, instances):
        """Calculate resource usage based on instance utilization.  This is
        different than the hypervisor's view as it will account for all
        instances assigned to the local compute host, even if they are not
        currently powered on.
        """
        self.tracked_instances.clear()

        # purge old stats
        self.stats.clear()

        # set some intiial values, reserve room for host/hypervisor:
        resources['local_gb_used'] = FLAGS.reserved_host_disk_mb / 1024
        resources['memory_mb_used'] = FLAGS.reserved_host_memory_mb
        resources['vcpus_used'] = 0
        resources['free_ram_mb'] = (resources['memory_mb'] -
                                    resources['memory_mb_used'])
        resources['free_disk_gb'] = (resources['local_gb'] -
                                     resources['local_gb_used'])
        resources['current_workload'] = 0
        resources['running_vms'] = 0

        for instance in instances:
            self._update_usage_from_instance(resources, instance)

def _update_usage_from_instance(self, resources, instance):
        """Update usage for a single instance."""

        uuid = instance['uuid']
        is_new_instance = uuid not in self.tracked_instances
        is_deleted_instance = instance['vm_state'] == vm_states.DELETED

        if is_new_instance:
            self.tracked_instances[uuid] = 1
            sign = 1

        if instance['vm_state'] == vm_states.DELETED:
            self.tracked_instances.pop(uuid)
            sign = -1

        self.stats.update_stats_for_instance(instance)

        # if it's a new or deleted instance:
        if is_new_instance or is_deleted_instance:
            # new instance, update compute node resource usage:
            resources['memory_mb_used'] += sign * instance['memory_mb']
            resources['local_gb_used'] += sign * instance['root_gb']
            resources['local_gb_used'] += sign * instance['ephemeral_gb']

            # free ram and disk may be negative, depending on policy:
            resources['free_ram_mb'] = (resources['memory_mb'] -
                                        resources['memory_mb_used'])
            resources['free_disk_gb'] = (resources['local_gb'] -
                                         resources['local_gb_used'])

            resources['running_vms'] = self.stats.num_instances
            resources['vcpus_used'] = self.stats.num_vcpus_used
        resources['current_workload'] = self.stats.calculate_workload()
        resources['stats'] = self.stats

"""libvirt.driver.get_available_resource""""

def get_available_resource(self):
    """Retrieve resource info.

    This method is called as a periodic task and is used only
    in live migration currently.

    :returns: dictionary containing resource info
    libvrit api examples:
    >>> import libvirt
    >>> conn = libvirt.openReadOnly("qemu:///system")
    >>> conn.getInfo()
    ['x86_64', 24049, 8, 1197, 2, 1, 4, 1]
    >>> conn.getVersion()
    1003001
    >>> conn.getType()
    'QEMU'
    >>> conn.getHostname()
    'trystack-manager'
    >>> conn.listDomainsID()
    [4, 5, 1, 27, 10, 3, 2]
    >>> dom = conn.lookupByID(4)
    >>> dom.name()
    'instance-00000031'
    >>> int(os.path.getsize('/var/lib/nova/instances/instance-00000031/disk'))
    35651584
    >>> os.system("qemu-img info /var/lib/nova/instances/instance-00000031/disk")
    image: /var/lib/nova/instances/instance-00000031/disk
    file format: qcow2
    virtual size: 24M (25165824 bytes)
    disk size: 15M
    cluster_size: 2097152
    0
    >>> dom
    <libvirt.virDomain instance at 0x7ffdc5bca170>
    >>> xml = dom.XMLDesc(0)
    >>> from lxml import etree
    >>> doc = etree.fromstring(xml)
    >>> doc.findall('.//devices/disk/driver')
    [<Element driver at 0x2004f00>, <Element driver at 0x2004e60>]
    >>> driver_nodes = doc.findall('.//devices/disk/driver')
    >>> path_nodes = doc.findall('.//devices/disk/source')
    >>> disk_nodes = doc.findall('.//devices/disk')
    >>> enumerate(path_nodes)
    <enumerate object at 0x2004d20>
    >>> list(path_nodes)
    [<Element source at 0x2004fa0>]
    >>> l = enumerate(path_nodes)
    >>> l.next()
    (0, <Element source at 0x2004fa0>)
    >>> l = enumerate(path_nodes)
    >>> i, ele = l.next()
    >>> disk_nodes[i].get('type')
    'file'
    >>> ele.get('file')
    '/var/lib/nova/instances/instance-00000031/disk'
    >>> driver_nodes[i].get('type')
    'qcow2'
    >>> from nova.virt import images
    >>> d = images.qemu_img_info(ele.get('file'))
    >>> d
    {'file format': 'qcow2', 'image': '/var/lib/nova/instances/instance-00000031/disk', 'disk size': '15M', 'virtual size': '24M (25165824 bytes)', 'cluster_size': '2097152'}
    >>> d.get('backing file')
    >>>
    """
    dic = {'vcpus': self.get_vcpu_total(), #multiprocessing.cpu_count()
           'vcpus_used': self.get_vcpu_used(), #host instance vcpu
           'memory_mb': self.get_memory_mb_total(), #conn.getInfo()[1]
           'memory_mb_used': self.get_memory_mb_used(), #total - free(buggers/cache)
           'local_gb': self.get_local_gb_total(), #total HDD $instance_path
           'local_gb_used': self.get_local_gb_used(), #used HDD $instance_path

           'hypervisor_type': self.get_hypervisor_type(), #conn.get_type()=QEMU
           'hypervisor_version': self.get_hypervisor_version(), #conn.getVersion()=1003001
           'hypervisor_hostname': self.get_hypervisor_hostname(),#conn.getHostname()=trystack-manager
           'cpu_info': self.get_cpu_info(), #cpu architure
           'disk_available_least': self.get_disk_available_least()}
    return dic

#########################
def get_disk_available_least(self):
        """Return disk available least size.

        The size of available disk, when block_migration command given
        disk_over_commit param is FALSE.

        The size that deducted real nstance disk size from the total size
        of the virtual disk of all instances.

        """
        # available size of the disk
        dk_sz_gb = self.get_local_gb_total() - self.get_local_gb_used()

        # Disk size that all instance uses : virtual_size - disk_size
        instances_name = self.list_instances()
        instances_sz = 0
        for i_name in instances_name:
            try:
                disk_infos = jsonutils.loads(
                        self.get_instance_disk_info(i_name))
                for info in disk_infos:
                    i_vt_sz = int(info['virt_disk_size'])
                    i_dk_sz = int(info['disk_size'])
                    instances_sz += i_vt_sz - i_dk_sz
            except OSError as e:
                if e.errno == errno.ENOENT:
                    LOG.error(_("Getting disk size of %(i_name)s: %(e)s") %
                              locals())
                else:
                    raise
            except exception.InstanceNotFound:
                # Instance was deleted during the check so ignore it
                pass
            # NOTE(gtt116): give change to do other task.
            greenthread.sleep(0)
        # Disk available least size
        available_least_size = dk_sz_gb * (1024 ** 3) - instances_sz
        return (available_least_size / 1024 / 1024 / 1024)


def get_memory_mb_used(self):
        """Get the free memory size(MB) of physical computer.

        :returns: the total usage of memory(MB).

        """

        if sys.platform.upper() not in ['LINUX2', 'LINUX3']:
            return 0

        m = open('/proc/meminfo').read().split()
        idx1 = m.index('MemFree:')
        idx2 = m.index('Buffers:')
        idx3 = m.index('Cached:')
        if FLAGS.libvirt_type == 'xen':
            used = 0
            for domain_id in self.list_instance_ids():
                # skip dom0
                dom_mem = int(self._conn.lookupByID(domain_id).info()[2])
                if domain_id != 0:
                    used += dom_mem
                else:
                    # the mem reported by dom0 is be greater of what
                    # it is being used
                    used += (dom_mem -
                             (int(m[idx1 + 1]) +
                              int(m[idx2 + 1]) +
                              int(m[idx3 + 1])))
            # Convert it to MB
            return used / 1024
        else:
            avail = (int(m[idx1 + 1]) + int(m[idx2 + 1]) + int(m[idx3 + 1]))
            # Convert it to MB
            return self.get_memory_mb_total() - avail / 1024


def get_fs_info(path):
            """Get free/used/total space info for a filesystem

            :param path: Any dirent on the filesystem
            :returns: A dict containing:

                     :free: How much space is free (in bytes)
                     :used: How much space is used (in bytes)
                     :total: How big the filesystem is (in bytes)
            """
            hddinfo = os.statvfs(path)
            total = hddinfo.f_frsize * hddinfo.f_blocks
            free = hddinfo.f_frsize * hddinfo.f_bavail
            used = hddinfo.f_frsize * (hddinfo.f_blocks - hddinfo.f_bfree)
            return {'total': total,
                    'free': free,
                    'used': used}


def get_local_gb_used(self):
        """Get the free hdd size(GB) of physical computer.

        :returns:
           The total usage of HDD(GB).
           Note that this value shows a partition where
           NOVA-INST-DIR/instances mounts.

        """

        stats = get_fs_info(FLAGS.instances_path)
        return stats['used'] / (1024 ** 3)


def get_local_gb_total():
        """Get the total hdd size(GB) of physical computer.

        :returns:
            The total amount of HDD(GB).
            Note that this value shows a partition where
            NOVA-INST-DIR/instances mounts.

        """

        stats = get_fs_info(FLAGS.instances_path)
        return stats['total'] / (1024 ** 3)

def get_vcpu_total():
        """Get vcpu number of physical computer.

        :returns: the number of cpu core.

        """

        # On certain platforms, this will raise a NotImplementedError.
        try:
            return multiprocessing.cpu_count()
        except NotImplementedError:
            LOG.warn(_("Cannot get the number of cpu, because this "
                       "function is not implemented for this platform. "
                       "This error can be safely ignored for now."))
            return 0
def get_memory_mb_total(self):
        """Get the total memory size(MB) of physical computer.

        :returns: the total amount of memory(MB).

        """

        return self._conn.getInfo()[1]

def get_vcpu_used(self):
        """ Get vcpu usage number of physical computer.

        :returns: The total number of vcpu that currently used.

        """

        total = 0
        for dom_id in self.list_instance_ids():
            dom = self._conn.lookupByID(dom_id)
            vcpus = dom.vcpus()
            if vcpus is None:
                # dom.vcpus is not implemented for lxc, but returning 0 for
                # a used count is hardly useful for something measuring usage
                total += 1
            else:
                total += len(vcpus[1])
            # NOTE(gtt116): give change to do other task.
            greenthread.sleep(0)
        return total


{% endhighlight %}
