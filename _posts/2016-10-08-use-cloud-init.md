---
layout: post
category: openstack
title: How to use cloud-init
tags: [linux, openstack]

---

### how to use cloud-init

#### inside vm(ubuntu1404)

`$ apt-cache search cloud-init`  

    cloud-init - Init scripts for cloud instances

`$ sudo apt-get --download-only install cloud-init`

    f9215960baf8de0e59e0e81844d8e9dc  cloud-init_0.7.5-0ubuntu1.21_all.deb

`root@first-vm:/usr/lib/python2.7/dist-packages/cloudinit# which cloud-init` 

    /usr/bin/cloud-init

`root@first-vm:/usr/lib/python2.7/dist-packages/cloudinit# which cloud-init-per ` 

    /usr/bin/cloud-init-per

`root@first-vm:/usr/lib/python2.7/dist-packages/cloudinit# cloud-init -h`

    usage: cloud-init [-h] [--version] [--file FILES] [--debug] [--force]
                      {init,modules,query,single} ...

    positional arguments:
      {init,modules,query,single}
        init                initializes cloud-init and performs initial modules
        modules             activates modules using a given configuration key
        query               query information stored in cloud-init
        single              run a single module

    optional arguments:
      -h, --help            show this help message and exit
      --version, -v         show program's version number and exit
      --file FILES, -f FILES
                            additional yaml configuration files to use
      --debug, -d           show additional pre-action logging (default: False)
      --force               force running even if no datasource is found (use at
                            your own risk)

`root@first-vm:/usr/lib/python2.7/dist-packages/cloudinit# cloud-init-per -h     `

    Usage: cloud-init-per frequency name cmd [ arg1 [ arg2 [ ... ] ]
       run cmd with arguments provided.

       This utility can make it easier to use boothooks or bootcmd
       on a per "once" or "always" basis.

       If frequency is:
          * once: run only once (do not re-run for new instance-id)
          * instance: run only the first boot for a given instance-id
          * always: run every boot

#### /etc/cloud/cloud.cfg

    # The top level settings are used as module
    # and system configuration.

    # A set of users which may be applied and/or used by various modules
    # when a 'default' entry is found it will reference the 'default_user'
    # from the distro configuration specified below
    users:
       - default

    # If this is set, 'root' will not be able to ssh in and they 
    # will get a message to login instead as the above $user (ubuntu)
    disable_root: true

    # This will cause the set+update hostname module to not operate (if true)
    preserve_hostname: false

    # Example datasource config
    # datasource: 
    #    Ec2: 
    #      metadata_urls: [ 'blah.com' ]
    #      timeout: 5 # (defaults to 50 seconds)
    #      max_wait: 10 # (defaults to 120 seconds)

    # The modules that run in the 'init' stage
    cloud_init_modules:
     - migrator
     - seed_random
     - bootcmd
     - write-files
     - growpart
     - resizefs
     - set_hostname
     - update_hostname
     - update_etc_hosts
     - ca-certs
     - rsyslog
     - users-groups
     - ssh

    # The modules that run in the 'config' stage
    cloud_config_modules:
    # Emit the cloud config ready event
    # this can be used by upstart jobs for 'start on cloud-config'.
     - emit_upstart
     - disk_setup
     - mounts
     - ssh-import-id
     - locale
     - set-passwords
     - grub-dpkg
     - apt-pipelining
     - apt-configure
     - package-update-upgrade-install
     - landscape
     - timezone
     - puppet
     - chef
     - salt-minion
     - mcollective
     - disable-ec2-metadata
     - runcmd
     - byobu

    # The modules that run in the 'final' stage
    cloud_final_modules:
     - rightscale_userdata
     - scripts-vendor
     - scripts-per-once
     - scripts-per-boot
     - scripts-per-instance
     - scripts-user
     - ssh-authkey-fingerprints
     - keys-to-console
     - phone-home
     - final-message
     - power-state-change

    # System and/or distro specific settings
    # (not accessible to handlers/transforms)
    system_info:
       # This will affect which distro class gets used
       distro: ubuntu
       # Default user name + that default users groups (if added/used)
       default_user:
         name: ubuntu
         lock_passwd: True
         gecos: Ubuntu
         groups: [adm, audio, cdrom, dialout, dip, floppy, netdev, plugdev, sudo, video]
         sudo: ["ALL=(ALL) NOPASSWD:ALL"]
         shell: /bin/bash
       # Other config here will be given to the distro class and/or path classes
       paths:
          cloud_dir: /var/lib/cloud/
          templates_dir: /etc/cloud/templates/
          upstart_dir: /etc/init/
       package_mirrors:
         - arches: [i386, amd64]
           failsafe:
             primary: http://archive.ubuntu.com/ubuntu
             security: http://security.ubuntu.com/ubuntu
           search:
             primary:
               - http://%(ec2_region)s.ec2.archive.ubuntu.com/ubuntu/
               - http://%(availability_zone)s.clouds.archive.ubuntu.com/ubuntu/
               - http://%(region)s.clouds.archive.ubuntu.com/ubuntu/
             security: []
         - arches: [armhf, armel, default]
           failsafe:
             primary: http://ports.ubuntu.com/ubuntu-ports
             security: http://ports.ubuntu.com/ubuntu-ports
       ssh_svcname: ssh

#### cloud-init-output.log
`$ cat cloud-init-output.log | grep running`

    Cloud-init v. 0.7.5 running 'init-local' at Tue, 21 Feb 2017 03:23:04 +0000. Up 3.76 seconds.
    Cloud-init v. 0.7.5 running 'init' at Tue, 21 Feb 2017 03:23:06 +0000. Up 5.73 seconds.
    Cloud-init v. 0.7.5 running 'modules:config' at Tue, 21 Feb 2017 03:23:17 +0000. Up 16.48 seconds.
    Cloud-init v. 0.7.5 running 'modules:final' at Tue, 21 Feb 2017 03:23:23 +0000. Up 23.06 seconds.
    
#### cloud-init by manually

`root@first-vm:/usr/lib/python2.7/dist-packages/cloudinit# cloud-init --debug init` 

cloud-init init 默认只init执行一次， semaphore位置/var/lib/cloud/instance/obj.pkl，/var/lib/cloud/data/no-net 

`root@first-vm:/usr/lib/python2.7/dist-packages/cloudinit# cloud-init single -n cc_xx`

    # args = Namespace(action=('single', <function main_single at 0x7fc67f9112a8>), debug=False, files=None, force=False, frequency=None, module_args=[], name='cc_xx')
    Cloud-init v. 0.7.5 running 'single' at Tue, 21 Feb 2017 07:33:47 +0000. Up 15047.18 seconds.
    2017-02-21 07:33:48,019 - stages.py[WARNING]: Could not find module named cc_xx
    2017-02-21 07:33:48,020 - cloud-init[WARNING]: Did not run cc_xx, does it exist?

`cloud-init --debug modules -m config (repeat running log show below)`

    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-disk_setup already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-mounts already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-ssh-import-id already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-locale already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-set-passwords already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-grub-dpkg already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-apt-pipelining already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-apt-configure already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-package-update-upgrade-install already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-landscape already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-timezone already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-puppet already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-chef already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-salt-minion already ran (freq=once-per-instance)
    Feb 21 08:06:53 first-vm [CLOUDINIT] helpers.py[DEBUG]: config-mcollective already ran (freq=once-per-instance)

`cloud-init --debug modules -m final`

#### /var/lib/cloud/scripts/

`root@first-vm:/var/lib/cloud/scripts/per-boot# tree /var/lib/cloud/`

    /var/lib/cloud/
    ├── data
    │   ├── instance-id
    │   ├── previous-datasource
    │   ├── previous-hostname
    │   ├── previous-instance-id
    │   ├── result.json
    │   └── status.json
    ├── handlers
    ├── instance
    │   └── boot-finished
    ├── instances
    │   └── db97088f-55f3-4997-8519-f028cc3764c0
    │       ├── cloud-config.txt
    │       ├── datasource
    │       ├── handlers
    │       ├── obj.pkl
    │       ├── scripts
    │       ├── sem
    │       │   ├── config_apt_configure
    │       │   ├── config_apt_pipelining
    │       │   ├── config_byobu
    │       │   ├── config_ca_certs
    │       │   ├── config_chef
    │       │   ├── config_disk_setup
    │       │   ├── config_grub_dpkg
    │       │   ├── config_keys_to_console
    │       │   ├── config_landscape
    │       │   ├── config_locale
    │       │   ├── config_mcollective
    │       │   ├── config_mounts
    │       │   ├── config_package_update_upgrade_install
    │       │   ├── config_phone_home
    │       │   ├── config_power_state_change
    │       │   ├── config_puppet
    │       │   ├── config_rightscale_userdata
    │       │   ├── config_rsyslog
    │       │   ├── config_runcmd
    │       │   ├── config_salt_minion
    │       │   ├── config_scripts_per_instance
    │       │   ├── config_scripts_user
    │       │   ├── config_scripts_vendor
    │       │   ├── config_seed_random
    │       │   ├── config_set_hostname
    │       │   ├── config_set_passwords
    │       │   ├── config_ssh
    │       │   ├── config_ssh_authkey_fingerprints
    │       │   ├── config_ssh_import_id
    │       │   ├── config_timezone
    │       │   ├── config_users_groups
    │       │   ├── config_write_files
    │       │   └── consume_data
    │       ├── user-data.txt
    │       ├── user-data.txt.i
    │       ├── vendor-data.txt
    │       └── vendor-data.txt.i
    ├── scripts
    │   ├── per-boot
    │   │   └── test.sh
    │   ├── per-instance
    │   ├── per-once
    │   └── vendor
    ├── seed
    └── sem
        └── config_scripts_per_once.once


`root@first-vm:/var/lib/cloud/scripts/per-boot# ll /var/lib/cloud/scripts/per-boot/`

    # chmod +X
    -rwxr-xr-x 1 root root   62 Feb 23 03:07 test.sh*

    # content
    #!/bin/sh
    echo "test echo"

#### code

    # stage.Init.paths
    self.paths: {'lookups': {'cloud_config': 'cloud-config.txt', 'userdata': 'user-data.txt.i', 'vendordata': 'vendor-data.txt.i', 'userdata_raw': 'user-data.txt', 'boothooks': 'boothooks', 'scripts': 'scripts', 'sem': 'sem', 'data': 'data', 'vendor_scripts': 'scripts/vendor', 'handlers': 'handlers', 'obj_pkl': 'obj.pkl', 'vendordata_raw': 'vendor-data.txt', 'vendor_cloud_config': 'vendor-cloud-config.txt'}, 'template_tpl': '/etc/cloud/templates/%s.tmpl', 'cfgs': {'cloud_dir': '/var/lib/cloud/', 'templates_dir': '/etc/cloud/templates/', 'upstart_dir': '/etc/init/'}, 'cloud_dir': '/var/lib/cloud/', 'datasource': <cloudinit.sources.DataSourceOpenStack.DataSourceOpenStack object at 0x7fe148080610>, 'upstart_conf_d': '/etc/init/', 'boot_finished': '/var/lib/cloud/instance/boot-finished', 'instance_link': '/var/lib/cloud/instance', 'seed_dir': '/var/lib/cloud/seed'}

### 业务场景
