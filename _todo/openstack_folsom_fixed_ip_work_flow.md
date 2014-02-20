##openstack folsom fixed ip work flow

### NetworkManager.init_host

#### NetworkManager.init_host
	def init_host(self):
        """Do any initialization that needs to be run if this is a
        standalone service.
        """
        # NOTE(vish): Set up networks for which this host already has
        #             an ip address.
        ctxt = context.get_admin_context()
        for network in self.db.network_get_all_by_host(ctxt, self.host):
            self._setup_network_on_host(ctxt, network)
#### FlatManager.init_host
#### FlatDHCPManager.init_host
	def init_host(self):
        """Do any initialization that needs to be run if this is a
        standalone service.
        """
        self.l3driver.initialize()
        super(FlatDHCPManager, self).init_host()
        self.init_host_floating_ips()
#### VlanManager.init_host
	def init_host(self):
        """Do any initialization that needs to be run if this is a
        standalone service.
        """

        self.l3driver.initialize()
        NetworkManager.init_host(self)
        self.init_host_floating_ips()
---
#### network.manager.py: Floating.init_host_floating_ips
	def init_host_floating_ips(self):
        """Configures floating ips owned by host."""
        floating_ips = self.db.floating_ip_get_all_by_host(admin_context,
                                                               self.host)
        for floating_ip in floating_ips:
            fixed_ip_id = floating_ip.get('fixed_ip_id')
            if fixed_ip_id:
                fixed_ip_ref = self.db.fixed_ip_get(admin_context,
                                                        fixed_ip_id)
                fixed_address = fixed_ip_ref['address']
                interface = FLAGS.public_interface or floating_ip['interface']
                try:
                    self.l3driver.add_floating_ip(floating_ip['address'],
                            fixed_address, interface)
                except exception.ProcessExecutionError:
                    LOG.debug(_('Interface %(interface)s not found'), locals())
                    raise exception.NoFloatingIpInterface(interface=interface)
---
#### L3driver.initialize: network.l3.LinuxNetL3.initialize
	def initialize(self, **kwargs):
        if self.initialized:
            return
        LOG.debug("Initializing linux_net L3 driver")
        linux_net.init_host()
        linux_net.ensure_metadata_ip()
        linux_net.metadata_forward()
        self.initialized = True
#### network.linux_net.py: init_host
	def init_host(ip_range=None):
    	"""Basic networking setup goes here."""
    	# NOTE(devcamcar): Cloud public SNAT entries and the default
    	# SNAT rule for outbound traffic.
    	if not ip_range:
        	ip_range = FLAGS.fixed_range

    	add_snat_rule(ip_range)

    	iptables_manager.ipv4['nat'].add_rule('POSTROUTING',
                                          '-s %s -d %s/32 -j ACCEPT' %
                                          (ip_range, FLAGS.metadata_host))

    	for dmz in FLAGS.dmz_cidr:
        	iptables_manager.ipv4['nat'].add_rule('POSTROUTING',
                                              '-s %s -d %s -j ACCEPT' %
                                              (ip_range, dmz))

    	iptables_manager.ipv4['nat'].add_rule('POSTROUTING',
                                          '-s %(range)s -d %(range)s '
                                          '-m conntrack ! --ctstate DNAT '
                                          '-j ACCEPT' %
                                          {'range': ip_range})
    	iptables_manager.apply()
#### network.linux_net.py: ensure_metadata_ip()
>ip addr add 169.254.169.254/32 scope link dev lo

	def ensure_metadata_ip():
    	"""Sets up local metadata ip."""
    	_execute('ip', 'addr', 'add', '169.254.169.254/32',
             'scope', 'link', 'dev', 'lo',
             run_as_root=True, check_exit_code=[0, 2, 254])
#### network.linux_net.py: metadata_forward()
	def metadata_forward():
    	"""Create forwarding rule for metadata."""
    	if FLAGS.metadata_host != '127.0.0.1':
        	iptables_manager.ipv4['nat'].add_rule('PREROUTING',
                                          '-s 0.0.0.0/0 -d 169.254.169.254/32 '
                                          '-p tcp -m tcp --dport 80 -j DNAT '
                                          '--to-destination %s:%s' %
                                          (FLAGS.metadata_host,
                                           FLAGS.metadata_port))
    	else:
        	iptables_manager.ipv4['nat'].add_rule('PREROUTING',
                                          '-s 0.0.0.0/0 -d 169.254.169.254/32 '
                                          '-p tcp -m tcp --dport 80 '
                                          '-j REDIRECT --to-ports %s' %
                                           FLAGS.metadata_port)
    	iptables_manager.apply()

---

### shell: instance and fixed ip

>1. ip link show dev vlan100
2. ip link add link eth0 name vlan100 type vlan id 100
3. ip link set vlan100 address fa:16:3e:0c:ae:4a
4. ip link set vlan100 up
5. --
6. ip link show dev br100
7. brctl setfd br100 0
8. brctl stp br100 of
9. ip link set br100 up
10. brctl addif br100 vlan100
11. ip route show dev vlan100
12. ip addr show dev vlan100 scope global
13. ip addr show dev br100
14. ip addr add 172.100.0.4/24 brd 172.100.0.255 dev br100

---

### code: instance and fixed ip

1.network/manager.py: *allocate_fixed_ip*

	address = self.db.fixed_ip_associate_pool(context, network['id'], 
									instance['uuid'])
	self._do_trigger_security_group_members_refresh_for_instance(
									instance_id)
    vif = self.db.virtual_interface_get_by_instance_and_network(
            context, instance['uuid'], network['id'])
    values = {'allocated': True,
              'virtual_interface_id': vif['id']}
    self.db.fixed_ip_update(context, address, values)
    self._setup_network_on_host(context, network)
    return address
    
2.db/api/sqlalchemy/api.py: *fixed_ip_associate_pool*

	@require_admin_context
	def fixed_ip_associate_pool(context, network_id, instance_uuid=None,
                            host=None):
    session = get_session()
    with session.begin():
        network_or_none = or_(models.FixedIp.network_id == network_id,
                              models.FixedIp.network_id == None)
        fixed_ip_ref = model_query(context, models.FixedIp, session=session,
                                   read_deleted="no").\
                               filter(network_or_none).\
                               filter_by(reserved=False).\
                               filter_by(instance_uuid=None).\
                               filter_by(host=None).\
                               with_lockmode('update').\
                               first()
        if not fixed_ip_ref:
            raise exception.NoMoreFixedIps()
        if fixed_ip_ref['network_id'] is None:
            fixed_ip_ref['network'] = network_id
        if instance_uuid:
            fixed_ip_ref['instance_uuid'] = instance_uuid
        if host:
            fixed_ip_ref['host'] = host
        session.add(fixed_ip_ref) #update fixed ip db info
    return fixed_ip_ref['address']
     
3.network/manager.py: VlanManager: *_setup_network_on_host*

    def _setup_network_on_host(self, context, network):
        """Sets up network on this host."""
        address = network['vpn_public_address']
        network['dhcp_server'] = self._get_dhcp_ip(context, network)

        self.l3driver.initialize_gateway(network)
        
        if not FLAGS.fake_network:
            dev = self.driver.get_dev(network)
            self.driver.update_dhcp(context, dev, network)
   
4.network/manager.py: NetworkManager: *_get_dhcp_ip*
	
	@utils.synchronized('get_dhcp')
    def _get_dhcp_ip(self, context, network_ref, host=None):
    	#br100 ip
        if not network_ref.get('multi_host'):
            return network_ref['gateway']

        if not host:
            host = self.host
        network_id = network_ref['id']
        try:
        	#the default is not found exception
            fip = self.db.fixed_ip_get_by_network_host(context,
                                                       network_id,
                                                       host)
            return fip['address']
        except exception.FixedIpNotFoundForNetworkHost:
            elevated = context.elevated()
            return self.db.fixed_ip_associate_pool(elevated,
                                                   network_id,
                                                   host=host) 