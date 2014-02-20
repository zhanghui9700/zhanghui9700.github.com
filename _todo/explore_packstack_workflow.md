#explore packstack workflow
### 1. first get the soure code from github

    git clone https://github.com/stackforge/packstack.git

\> tree packstack -L 1
                                              
	packstack
	|-- bin
	|-- docs
	|-- LICENSE
	|-- MANIFEST.in
	|-- packstack
	|-- README
	|-- requirements.txt
	|-- run_tests.sh
	|-- setup.py
	|-- spec
	|-- tests
	|-- tools
	`-- tox.ini

	6 directories, 7 files
	
### 2. let's go to the internal of the code
	
\> cat ./bin/packstack

	#!/usr/bin/env python
	import os, sys

	try:
    	import packstack
	except ImportError:
    	# packstack isn't installed, running from source checkout
    	sys.path.insert(0, os.path.join(os.path.split(sys.argv[0])[0], ".."))
    	import packstack

	os.environ["INSTALLER_PROJECT_DIR"] = os.path.abspath(os.path.split(packstack.__file__)[0])

	from packstack.installer import run_setup
	run_setup.main()
	
\> tree packstack/installer -L 1

	`packstack/installer
	|-- basedefs.py
	|-- core
	|-- exceptions.py
	|-- __init__.py
	|-- LICENSE
	|-- output_messages.py
	|-- processors.py
	|-- run_setup.py
	|-- setup_controller.py
	|-- utils
	`-- validators.py
	
	2 directori`es, 9 files
	
\> vi packstack/installer/run_setup.py

	def main():
	    try:
            # Load All plugins from packstack/plugins/xxx_dd.py order by dd 
            # and do controller.addPlugin(plugin)
	        loadPlugins() 
            # for plugin: do controller.addGroup(group_dict, group_params)
	        initPluginsConfig()
	
	        optParser = initCmdLineParser()
			(options, args) = optParser.parse_args()
	
	        # Initialize logging
	        initLogging (options.debug)
	
	        # Parse parameters
	        runConfiguration = True
	        confFile = None
	
	        controller.CONF['DEFAULT_EXEC_TIMEOUT'] = options.timeout
	        controller.CONF['DRY_RUN'] = options.dry_run
	
	        if options.gen_answer_file:
	            validateSingleFlag(options, "gen_answer_file")
	            generateAnswerFile(options.gen_answer_file)
	        elif options.allinone:
            	single_step_aio_install(options)
	        elif options.install_hosts:
	            single_step_install(options)
	        # Otherwise, run main()
	        else:
	            if options.answer_file:
	                validateSingleFlag(options, "answer_file")
	                confFile = os.path.expanduser(options.answer_file)
	            else:
	                _set_command_line_values(options)
	            _main(confFile)
	    finally:
        	remove_remote_var_dirs()

        	# Always print user params to log
        	_printAdditionalMessages()
        	_summaryParamsToLog()
        	
### ./bin/packstack --gen-answer-file=/tmp/ans.file

	def generateAnswerFile(outputFile, overrides={}):
	    sep = os.linesep
	    fmt = ("%(comment)s%(separator)s%(conf_name)s=%(default_value)s"
	           "%(separator)s")
	
	    outputFile = os.path.expanduser(outputFile)
	    fd = os.open(outputFile, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0600)
	
	    with os.fdopen(fd, "w") as ans_file:
	        ans_file.write("[general]%s" % os.linesep)
	        for group in controller.getAllGroups():
	            ans_file.write("[***group***] %s %s" % (group.GROUP_NAME, os.linesep))
	            for param in group.parameters.itervalues():
	                comm = param.USAGE or ''
	                comm = textwrap.fill(comm,
	                                     initial_indent='%s# ' % sep,
	                                     subsequent_indent='# ',
	                                     break_long_words=False)
	                value = controller.CONF.get(param.CONF_NAME,
	                                            param.DEFAULT_VALUE)
	
	                args = {'comment': comm,
	                        'separator': sep,
	                        'default_value': overrides.get(param.CONF_NAME, value),
	                        'conf_name': param.CONF_NAME}
	                ans_file.write(fmt % args)
	                
#### the answer file format like this:
>[general] <br>
[***group***] GLOBAL <br>
\# Set to 'y' if you would like Packstack to install MySQL
CONFIG_MYSQL_INSTALL=y <br>
\# Set to 'y' if you would like Packstack to install OpenStack Image<br>
\# Service (Glance)<br>
CONFIG_GLANCE_INSTALL=y<br>
\# Set to 'y' if you would like Packstack to install OpenStack Block<br>
\# Storage (Cinder)<br>
CONFIG_CINDER_INSTALL=y<br>
\# Set to 'y' if you would like Packstack to install OpenStack Compute<br>
\# (Nova)<br>
CONFIG_NOVA_INSTALL=y<br>
[*group*] MYSQL<br>
\# The IP address of the server on which to install MySQL<br>
CONFIG_MYSQL_HOST=172.16.1.190<br>
\# Username for the MySQL admin user<br>
CONFIG_MYSQL_USER=root<br>
\# Password for the MySQL admin user<br>
CONFIG_MYSQL_PW=6fef294ae7ad42ff<br>
[***group***] QPIDLANCE<br>
\# The IP address of the server on which to install the QPID service<br>
CONFIG_QPID_HOST=172.16.1.190<br>
[***group***] KEYSTONE<br>
\# The IP address of the server on which to install Keystone<br>
CONFIG_KEYSTONE_HOST=172.16.1.190<br>
\# The password to use for the Keystone to access DB<br>
CONFIG_KEYSTONE_DB_PW=547a88ae5197410a<br>
	                
###./bin/packstack --allinone
	1. single_step_aio_install(options)
	2. single_step_install(options)
	3. generateAnswerFile
	4. _main(answerFile)

### ./bin/packstack --answer-file=/tmp/ans.file
#### go into the _main method, the kernel method
        	
    def _main(configFile=None):
	    print output_messages.INFO_HEADER
	
	    # Get parameters
	    _handleParams(configFile)
	
	    # Update masked_value_list with user input values
	    _updateMaskedValueSet()
	
	    # Print masked conf
	    logging.debug(mask(controller.CONF))
	
	    # Start configuration stage
	    print "\n",output_messages.INFO_INSTALL
	
	    # Initialize Sequences
	    initPluginsSequences()
	
	    # Run main setup logic
	    runSequences()
	
	    # Lock rhevm version
	    #_lockRpmVersion()
	
	    # Print info
	    _addFinalInfoMsg()
	    print output_messages.INFO_INSTALL_SUCCESS

	    
#### inside to plugins sequence
0. puppet_950.py
	1. runCleanup
		1. rm -rf /var/tmp/packstack/`date-random`/manifests/*pp
1. prescript_000.py
	1. install_keys(copy id_rsa.pub to all filtered_hosts)
		1. mkdir -p ~/.ssh
		2. chmod 500 ~/.ssh
		3. grep id_rsa.pub ~/.ssh/authorized_keys >/dev/null 2>&1 || echo id_rsa.pub >> ~/.ssh/authorized_keys 
		4. chmod 400 ~/.ssh/authorized_keys
		5. restorecon -r ~/.ssh
	2. discover(for all filtered_hosts)
		1. cat /etc/redhat-release
		2. mkdir -p /var/tmp/packstack
		3. mkdir --mode 0700 /var/tmp/packstack/`uuid`
		4. mkdir --mode 0700 /var/tmp/packstack/`uuid`/modules
		5. mkdir --mode 0700 /var/tmp/packstack/`uuid`/resources
	3. create_manifest(for all filtered_hosts)
		1. create `host`_prescript.pp to cache
2. mysql_001.py
	1. create_manifest
		1. create `CONFIG_MYSQL_HOST`_mysql.pp to cache(mysql_insall.pp)
3. keystone_100.py
	1. create_manifest
		1. create `CONFIG_KEYSTONE_HOST`_keystone.pp to cache(keystone.pp)
4. glance_200.py
	1. create_keystone_manifest
		1. create `CONFIG_KEYSTONE_HOST`_keystone.pp to cache(keystone_glance.pp)
	2. ceate_manifest
		1. create `CONFIG_GLANCE_HOST`_glance.pp to cache(glance.pp)
5. postscript_948.py
	1. create_manifest(for all filtered_hosts)
		1. create `host`_postscript.pp to cache(postscript.pp)
6. serverprep_949.py
	1. serverprep
		1. **TODO**
6. puppet_950.py
	1. install_deps(for all filtered_hosts)
		1. `rpm -q --whatprovides puppet || yum install -y puppet`
		2. `rpm -q --whatprovides openssh-clients || yum install -y openssh-clients`
		3. `rpm -q --whatprovides tar || yum install -y tar`
		4. `rpm -q --whatprovides nc || yum install -y nc`
	2. copy_puppet_modules
	3. apply_puppet_manifest
	4. finalize
		



---
	

    cd /root/packstack/packstack/puppet
    cd /var/tmp/packstack/20140310-074059-GgyJFS/manifests
    tar --dereference -cpzf - ../manifests | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.176.134 tar -C /var/tmp/packstack/6a6dc3b2621c444197a9e5bf9d497032 -xpzf -
    cd /usr/share/openstack-puppet/modules
    tar --dereference -cpzf - apache ceilometer certmonger cinder concat firewall glance heat horizon inifile keystone memcached mongodb mysql neutron nova nssdb openstack packstack qpid rsync ssh stdlib swift sysctl tempest vcsrepo vlan vswitch xinetd | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@192.168.176.134 tar -C /var/tmp/packstack/6a6dc3b2621c444197a9e5bf9d497032/modules -xpzf -



    export FACTERLIB=$FACTERLIB:/var/tmp/packstack/5fc92e35017f471fb90a2c122e0bceb0/facts
    touch /var/tmp/packstack/5fc92e35017f471fb90a2c122e0bceb0/manifests/192.168.176.134_prescript.pp.running
    chmod 600 /var/tmp/packstack/5fc92e35017f471fb90a2c122e0bceb0/manifests/192.168.176.134_prescript.pp.running
    export PACKSTACK_VAR_DIR=/var/tmp/packstack/5fc92e35017f471fb90a2c122e0bceb0
    ( flock /var/tmp/packstack/5fc92e35017f471fb90a2c122e0bceb0/ps.lock puppet apply --debug --modulepath /var/tmp/packstack/5fc92e35017f471fb90a2c122e0bceb0/modules /var/tmp/packstack/5fc92e35017f471fb90a2c122e0bceb0/manifests/192.168.176.134_prescript.pp > /var/tmp/packstack/5fc92e35017f471fb90a2c122e0bceb0/manifests/192.168.176.134_prescript.pp.running 2>&1 < /dev/null ; mv /var/tmp/packstack/5fc92e35017f471fb90a2c122e0bceb0/manifests/192.168.176.134_prescript.pp.running /var/tmp/packstack/5fc92e35017f471fb90a2c122e0bceb0/manifests/192.168.176.134_prescript.pp.finished ) > /dev/null 2>&1 < /dev/null &
