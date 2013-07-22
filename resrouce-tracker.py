#---
#/nova/virt/libvirt/driver.py
#---

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
           'hypervisor_hostname': self.get_hypervisor_hostname(),#conn.getHostname()=eayun-manager
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

