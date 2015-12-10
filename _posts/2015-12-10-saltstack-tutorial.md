---
layout: post
category: openstack
title: SaltStack Tutorial 
tags: [linux, saltstack]

---

1. [install by vagrant](#saltstack-insall)
1. [configuration](#saltstack-config)
1. [minion target pattern](#saltstack-target-pattern)
1. [salt modules](#saltstack-modules)
1. [custom modules](#saltstack-custom-modules)
1. [salt state](#saltstack-state)
1. [salt http api](#saltstack-http-api)

### launch saltstack by vagrant

#### 1. <a id="saltstack-install">install by vagrant</a>

>$ cat Vagrantfile

    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    Vagrant.configure(2) do |config|

      config.vm.define :node1 do |node1|
            node1.vm.box = "ubuntu1404"
            node1.vm.hostname = "salt-master"
            node1.vm.network :private_network, :ip => "172.16.200.100"
            node1.vm.network "public_network",:bridge => "eth0", auto_config: false
            node1.vm.synced_folder ".", "/vagrant", disabled: true
            node1.vm.provision "shell", inline: "apt-get install -y salt-master"
      end

      config.vm.define :node2 do |node2|
            node2.vm.box = "ubuntu1404"
            node2.vm.hostname = "salt-minion"
            node2.vm.network :private_network, :ip => "172.16.200.101"
            node2.vm.network "public_network",:bridge => "eth0", auto_config: false
            node2.vm.synced_folder ".", "/vagrant", disabled: true
            node2.vm.provision "shell", inline: "apt-get install -y salt-minion"
      end

      config.vm.provider "virtualbox" do |vb|
            vb.gui = false
            vb.customize ["modifyvm", :id, "--memory", "1024"]
            vb.customize ["modifyvm", :id, "--ioapic", "on"]
            vb.customize ["modifyvm", :id, "--cpus", "2"]
            #vb.customize ["modifyvm", :id, "--nic2", "intnet"]
            #vb.customize ["modifyvm", :id, "--nictype2", "Am79C973"]
      end

      config.vm.provision "shell" do |shell|
            shell.path = "./setup.sh"
      end
    end

>$ cat setup.sh


    #!/bin/bash

    echo "deb http://mirrors.163.com/ubuntu/ trusty main restricted universe multiverse" > /etc/apt/sources.list
    cat /etc/apt/sources.list
    ping -c 4 114.114.114.114
    apt-get update

>$ vagrant up

##### 注意，最好安装salt的最新release版本

    apt-get install software-properties-common python-software-properties
    sudo add-apt-repository ppa:saltstack/salt2015-5
    apt-get install -y salt-master

    salt --versions-report

                  Salt: 2015.5.3
                Python: 2.7.6 (default, Mar 22 2014, 22:59:56)
                Jinja2: 2.7.2
              M2Crypto: 0.21.1
        msgpack-python: 0.3.0
          msgpack-pure: Not Installed
              pycrypto: 2.6.1
               libnacl: Not Installed
                PyYAML: 3.10
                 ioflo: Not Installed
                 PyZMQ: 14.0.1
                  RAET: Not Installed
                   ZMQ: 4.0.4
                  Mako: 0.9.1
               Tornado: Not Installed
    Debian source package: 2015.5.3+ds-1trusty1


#### 2. <a id="saltstack-config"> config master/monion </a>

> at minion node, config salt master host and self id

    $ root@salt-minion:~# vi /etc/salt/minion
        # master: **salt-master**
        # id: **salt-minion**

    $ root@salt-minion:~# service salt-minion restart

> at master node, validate salt-key

    # list all salt minion keys status
    $ root@salt-master:~# salt-key
    # show fingerprients

如果/etc/salt/master中auto_accept不是True，那么需要手动签名

    root@salt-master:~# tree /etc/salt/
    /etc/salt/
    ├── master
    ├── master.d
    │   └── salt-api.conf
    └── pki
        └── master
            ├── master.pem
            ├── master.pub
            ├── minions
            ├── minions_autosign
            ├── minions_denied
            ├── minions_pre
            │   └── salt-minion  ### HERE
            └── minions_rejected


    $ root@salt-master:~# salt-key -f salt-minion
    # accept the key at master

    $ root@salt-master:~# salt-key -a salt-minion 

    # delete key
    salt-key -d MINION

    root@salt-master:~# tree /etc/salt/
    /etc/salt/
    ├── master
    ├── master.d
    │   └── salt-api.conf
    └── pki
        └── master
            ├── master.pem
            ├── master.pub
            ├── minions
            │   └── salt-minion  ### HERE
            ├── minions_autosign
            ├── minions_denied
            ├── minions_pre
            └── minions_rejected


> test it!

    $ root@salt-master:~# salt '*' test.ping
    $ root@salt-master:~# salt 'salt-minion' sys.doc test.ping

    test.ping:

        Just used to make sure the minion is up and responding
        Return True

        CLI Example:

            salt '*' test.ping

    root@salt-master:~# salt 'salt-minion' sys.list_functions | wc -l
    603
    root@salt-master:~# salt 'salt-minion' sys.list_modules | wc -l
    66

#### 3. <a name="saltstack-target-pattern">target pattern</a>

>Usage: salt [options] `'<target>'` `<function>` `[arguments]`

##### 3.1 global matching
> target = 'host-name'  
> target = '*'  
> target = 'my*'  
> target = 'my*client'  
> target = 'my??client'  
> target = 'my[a-z]client'  

##### 3.2 PCRE
> target = -E `'<exp>'`

##### 3.3 list matching
> target = -L `'a, b, c'`

##### 3.4 grains
> target = --grain 'os_familiy:RedHat'  
> target = -G 'os:Ubuntu'  
> target = -G 'os:centos*'  

> ##### salt '*' grains.items
> ##### cat /etc/salt/grains

##### 3.5 pillar
> TODO

##### 3.6 compound matching
> target = -C `'*minion and G@os:Ubuntu and not L@yourminion,theirminion'`  
> target = -C `'* and not G@os_family:RedHat'`  

    Letter  Match Type          Example
    G       Grains glob         G@os:Ubuntu
    E       PCRE minion ID      E@web\d+\.(dev|qa|prod)\.loc
    P       Grains PCRE         P@os:(RedHat|Fedora|CentOS)
    L       List of minions     L@minion1.example.com, minion3.domain.com
    I       Pillar glob         I@pdata:foobar
    S       Subnet/IP address   S@192.168.1.0/24 or S@192.168.1.100
    R       Range cluster       R@%foo.bar

#### 4. <a name="saltstack-modules">moduels</a>

    salt '*' sys.list_modules
    salt '*' sys.doc user.add  
    salt '*' user.info <User>  
    salt '*' sys.doc pkg.install  
    salt '*' pkg.install apache2
    salt '*' service.status apache2
    salt '*' status.diskusage
    salt '*' cmd.run 'echo HELLO'

#### 5. <a id="saltstack-custom-modules"> exploring the modules </a>

`# get the source code`

    git clone https://github.com/saltstack/salt.git
    ls -l salt/modules

`__salt__`

    {%highlight python %}
    call = __salt__['cmd.run_all'](cmd,
                                   output_loglevel='trace',
                                   python_shell=False)
    {%endhighlight%}

`__virtual__`

    {% highlight python %}

    # Define the module's virtual name
    __virtualname__ = 'pkg'


    def __virtual__():
        '''
        Confirm this module is on a Debian based system
        '''
        if __grains__.get('os_family', False) == 'Kali':
            return __virtualname__
        elif __grains__.get('os_family', False) == 'Debian':
            return __virtualname__
        return False

    {% endhighlight %}

`__opts__`

    # see: salt/modules/config.py

    {% highlight python %}

    def option(
        value,
        default='',
        omit_opts=False,
        omit_master=False,
        omit_pillar=False):
        '''
        Pass in a generic option and receive the value that will be assigned

        CLI Example:

        .. code-block:: bash

            salt '*' config.option redis.host
        '''
        if not omit_opts:
            if value in __opts__:
                return __opts__[value]
        if not omit_master:
            if value in __pillar__.get('master', {}):
                return __pillar__['master'][value]
        if not omit_pillar:
            if value in __pillar__:
                return __pillar__[value]
        if value in DEFAULTS:
            return DEFAULTS[value]
        return default
    {% endhighlight%}
`__pillar__`

    # TODO

##### 5.1 custom moduels

By defualt, custom modeuls path live in `/srv/salt/_modules`, create it by manual.

The first custom module, eonstack

    salt '*' eonstack.run_qos

##### 5.1.1 write python code

    cat /srv/salt/_modules/eonstack.py

    {% highlight python %}
    # -*- coding: utf-8 -*-

    from __future__ import absolute_import

    # Import python libs
    import os
    import logging
    import json

    # Import third party libs
    import yaml


    # Define the module's virtual name
    __virtualname__ = 'eonstack'


    def __virtual__():
        '''
        Confirm this module is on a Debian based system
        '''
        if __grains__.get('os_family', False) == 'Kali':
            return __virtualname__
        elif __grains__.get('os_family', False) == 'Debian':
            return __virtualname__

        return __virtualname__

    def echo(text):
        '''
        Return a string - used for testing the connection

        CLI Example:

        .. code-block:: bash

            salt '*' test.echo 'foo bar baz quo qux'
        '''
        return text


    {% endhighlight %}

##### 5.1.2 sync custom modules to all minion

    salt '*' saltutl.sync_util 
    [root@salt-master _modules]# salt '*' saltutil.sync_all
    salt-client1:
        ----------
        beacons:
        grains:
        modules:
            - modules.eonstack
        outputters:
        renderers:
        returners:
        states:
        utils:
    salt-master:
        ----------
        beacons:
        grains:
        modules:
            - modules.eonstack
        outputters:
        renderers:
        returners:
        states:
        utils:

##### 5.1.3 test it!

    [root@salt-master _modules]# salt '*' eonstack.echo 'hello world'

#### 6. <a id="saltstack-state"> State </a>

By default, states are located in the ***/srv/salt*** driectory. All Salt-specific files that aren't Python files and in the extension ***.sls***.

    # list all state modules
    salt "Minion" sys.list_state_modules
    # show state function
    salt "Mionion" sys.list_state_functions <STATE>
    # help
    salt 'Minion' sys.state_doc <STATE>
    salt 'Minion' sys.state_doc <STATE.func> 

##### 6.1 first example

    # cat /srv/salt/git.sls
    root@node-1:/srv/salt# cat /srv/salt/git.sls 
    ---
    install_git:
      pkg.installed:
        -
          name: git


    # run it
    root@node-1:/srv/salt# salt 'node-3*' state.sls git
    node-3.domain.tld:
    ----------
        State: - pkg
        Name:      git
        Function:  installed
            Result:    True
            Comment:   Package git is already installed
            Changes:

    Summary
    ------------
    Succeeded: 1
    Failed:    0
    ------------
    Total:     1

    # remove git package and rerun the states
    root@node-1:/srv/salt# salt 'node-3*' pkg.remove git

    root@node-1:/srv/salt# salt 'node-3*' state.sls git
    node-3.domain.tld:
    ----------
        State: - pkg
        Name:      git
        Function:  installed
            Result:    True
            Comment:   The following packages were installed/updated: git.
            Changes:   git: { new : 1:1.9.1-1ubuntu0.1
                            old :
                            }
                       git-core: { new : 1
                            old :
                            }
                       git-completion: { new : 1
                            old :
                            }


    Summary
    ------------
    Succeeded: 1
    Failed:    0
    ------------
    Total:     1

List the functions for a given state module with sys.list_functions.

    root@node-1:/srv/salt# salt 'node-3*' sys.list_functions pkg

    node-3.domain.tld:
        - pkg.available_version
        - pkg.del_repo
        - pkg.expand_repo_def
        - pkg.file_dict
        - pkg.file_list
        - pkg.get_repo
        - pkg.get_selections
        - pkg.install
        - pkg.latest_version
        - pkg.list_pkgs
        - pkg.list_repos
        - pkg.list_upgrades
        - pkg.mod_repo
        - pkg.purge
        - pkg.refresh_db
        - pkg.remove
        - pkg.set_selections
        - pkg.upgrade
        - pkg.upgrade_available
        - pkg.version
        - pkg.version_cmp

state declaration is called:

    <ID Declaration>:
        <State Module>.<Function>:
        - name: <name>
        - <Function Arg>
        - <Function Arg>
        - <Function Arg>
        - <Requisite Declaration>:
            - <Requisite Reference>

#### 7. <a id="saltstack-http-api"> HTTP REST API</a>

在master结点安装restapi `apt-get install -y salt-api`

构造ssl key

    openssl genrsa -out /root/salt-api/key.pem 4096
    openssl req -new -x509 -key /root/salt-api/key.pem -out /root/salt-api/cert.pem -days 1826

编辑rest server的配置文件如下[rest_cherrypy](http://salt-api.readthedocs.org/en/latest/ref/netapis/all/saltapi.netapi.rest_cherrypy.html#rest-cherrypy-auth)：

    root@salt-master:/etc/salt/master.d# cat /etc/salt/master.d/salt-api.conf
    rest_cherrypy:
      port: 8080
      host: 172.16.200.100
      ssl_crt: /root/salt-api/cert.pem
      ssl_key: /root/salt-api/key.pem
      webhook_disable_auth: True
      webhook_url: /hook
      collect_stats: True

创建API用户

    groupadd eonstack
    useradd -g eonstack -M -s /user/sbin/nologin -c 'saltstack rest api user for eonboard' eonstack
    passwd eonstack

设置salt-api验证用户的类型

    # cat /etc/salt/master

    # The external auth system uses the Salt auth modules to authenticate and
    # validate users to access areas of the Salt system.
    external_auth:
      pam:
        eonstack:
          - .*

重启服务`service salt-master restart && service salt-api restart`

验证API

    url_map = {
        'index': LowDataAdapter,
        'login': Login,
        'logout': Logout,
        'minions': Minions,
        'run': Run,
        'jobs': Jobs,
        'keys': Keys,
        'events': Events,
        'stats': Stats,
    }

##### index(GET/POST)

    # GET
    curl --insecure https://172.16.200.100:8080/index/ -H 'Accept: application/x-yaml' -d username='eonstack' -d password='password' -d eauth='pam' -X GET
    clients:
    - _is_master_running
    - local
    - local_async
    - local_batch
    - runner
    - runner_async
    - ssh
    - ssh_async
    - wheel
    - wheel_async
    return: Welcome

    # POST
    curl --insecure https://172.16.200.100:8080/index/ -H 'Accept: application/x-yaml' -H 'X-Auth-Token : badf65223c19084464a8e9315e5900a0efc100df' -d client=local -d tgt='*' -d fun=test.ping -X POST
    return:
    - salt-minion: true


##### login (GET/POST)


    # GET
    curl --insecure https://172.16.200.100:8080/login/ -H 'Accept: application/x-yaml' -d username='eonstack' -d password='password' -d eauth='pam' -X GET
    return: Please log in
    status: null

    # POST
    curl --insecure https://172.16.200.100:8080/login/ -H 'Accept: application/x-yaml' -d username='eonstack' -d password='password' -d eauth='pam' -X POST
    return:
    - eauth: pam
      expire: 1445633027.415278
      perms:
      - .*
      start: 1445589827.415275
      token: badf65223c19084464a8e9315e5900a0efc100df
      user: eonstack

##### logout (POST)

    # POST
    curl --insecure https://172.16.200.100:8080/logout/ -H 'Accept: application/x-yaml' -H 'X-Auth-Token : badf65223c19084464a8e9315e5900a0efc100df' -X POST
    return: Your token has been cleared

##### minions (GET/POST)

    # GET 
    curl --insecure https://172.16.200.100:8080/minions/ -H 'Accept: application/x-yaml' -H 'X-Auth-Token : 1e975aadb3149374c9e6d5c481b925845e736f2c' -X GET
    return:
    - salt-minion:
        grains.items 

    # GET BY not exist ID
    curl --insecure https://172.16.200.100:8080/minions/not-exists/ -H 'Accept: application/x-yaml' -H 'X-Auth-Token : 1e975aadb3149374c9e6d5c481b925845e736f2c' -X GET
    return:
    - {}

    # GET BY ID
    curl --insecure https://172.16.200.100:8080/minions/salt-minion/ -H 'Accept: application/x-yaml' -H 'X-Auth-Token : 1e975aadb3149374c9e6d5c481b925845e736f2c' -X GET
    return:
    - salt-minion:
        grains.items 

    # POST
    curl --insecure https://172.16.200.100:8080/minions/ -H 'Accept: application/x-yaml' -H 'X-Auth-Token : 1e975aadb3149374c9e6d5c481b925845e736f2c' -X POST -d tgt='*' -d fun='status.diskusage'
    _links:
      jobs:
      - href: /jobs/20151023090633311442
    return:
    - jid: '20151023090633311442'
      minions:
      - salt-minion 



##### jobs (GET)

    # GET JOB
    curl --insecure https://172.16.200.100:8080/jobs/20151023092345571347 -H 'Accept: application/x-yaml' -H 'X-Auth-Token : 4b01221fea2d1ec7026cf087a11724dbb7e44017' -X GET

    info:
    - Arguments: []
      Function: status.diskusage
      Minions:
      - salt-minion
      Result:
        salt-minion:
          return:
            /:
              available: 38232371200
              total: 41612050432
            /dev:
              available: 1038528512
              total: 1038532608
            /dev/pts:
              available: 0
              total: 0
     StartTime: 2015, Oct 23 09:23:45.571347
      Target: '*'
      Target-type: glob
      User: eonstack
      jid: '20151023092345571347'
    return:
    - salt-minion:
        /:
          available: 38232371200
          total: 41612050432
        /dev:
          available: 1038528512
          total: 1038532608
        /dev/pts:


    # GET JOB by not exist id
    root@salt-minion:~# curl --insecure https://172.16.200.100:8080/jobs/xxx -H 'Accept: application/x-yaml' -H 'X-Auth-Token : 4b01221fea2d1ec7026cf087a11724dbb7e44017' -X GET
    info:
    - Arguments: []
      Function: unknown-function
      Result: {}
      StartTime: ''
      Target: unknown-target
      Target-type: []
      User: root
      jid: xxx
    return:
    - {}

##### run(POST)

***need: user/password at the post body every tim***

    # POST
    curl --insecure https://172.16.200.100:8080/run -H 'Accept: application/json' -d username='eonstack' -d password='password' -d eauth='pam' -d client='local' -d tgt='*' -d fun='test.ping'
    {"return": [{"salt-minion": true}]}

    # POST
    curl --insecure https://172.16.200.100:8080/run/ -H 'Accept: application/x-yaml' -d username='eonstack' -d password='password' -d eauth='pam' -d client='local' -d tgt='*' -d fun='test.fib' -d arg=10
    return:
    - salt-minion:
      - - 0
        - 1
        - 1
        - 2
        - 3
        - 5
        - 8
      - 4.0531158447265625e-06
    
#### events(GET)

    # 监听事件 - 命令行
    $ salt-run state.event pretty=True

    # 监听事件 - HTTP Keep-alive
    $ curl -G -NsS --insecure https://10.6.14.212:8080/events -H "X-Auth-Token: 7e2a7e82876a36f1b6d4289f2561d80f2ef29ad4"
    retry: 400
    tag: salt/event/new_client
    data: {"tag": "salt/event/new_client", "data": {"_stamp": "2015-11-11T10:14:11.295501"}}

    # 监听事件 by python
    resp = requests.get("https://10.6.14.212:8080/events", verify=False, headers={'X-Auth-Token': '99c5dc46bdff4c40ca3e31b2f90291fe87518cee'}, stream=True)
    for line in resp.iter_lines():
        if(line):
            print line

#### reference

1. [SALT TABLE OF CONTENTS](https://docs.saltstack.com/en/latest/contents.html)
