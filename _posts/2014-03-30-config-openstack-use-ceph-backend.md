---
layout: post
category: openstack
title: config openstack use cpeh backend
tags: [linux, openstack, ceph]

---


##prapare to install
    # for all nodes
    sudo useradd -d /home/ceph -m ceph
    sudo passwd ceph
    echo "ceph ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph
    sudo chmod 0440 /etc/sudoers.d/ceph

##admin-node node(ceph and root)
    ssh-keygen
    vi ~/.ssh/config
    chmod 600 ~/.ssh/config

	[ceph@rdo-manager my-cluster]$ cat ~/.ssh/config 
    Host rdo-manager
    HostName 192.168.11.100
    User ceph
    Port 22
    
    Host rdo-compute1
    HostName 192.168.11.101
    User ceph
    Port 22

	ssh-copy-id ceph@rdo-manager  
	ssh-copy-id ceph@rdo-compute1

    ceph-deploy install host-name

这里ceph-deploy会安装wget并会配置ceph的yum源，不过我们希望rdo和ceph的源都用本地镜像，可以使用如下方法解决源内baseurl指向本地：

    export CEPH_DEPLOY_REPO_URL="http://your-mirrors/rpm-emperor/el6"
    export CEPH_DEPLOY_GPG_URL="http://your-mirrors/rpm-emperor/gpg.key"
 
---

    qemu-img -h | grep 'rbd'  
    
---

###config ceph cluster

>[root@eayun-admin ceph]# ceph-deploy disk list eayun-compute1

    [ceph_deploy.cli][INFO  ] Invoked (1.3.5): /usr/bin/ceph-deploy disk list eayun-compute1
    [eayun-compute1][DEBUG ] connected to host: eayun-compute1 
    [eayun-compute1][DEBUG ] detect platform information from remote host
    [eayun-compute1][DEBUG ] detect machine type
    [ceph_deploy.osd][INFO  ] Distro info: CentOS 6.5 Final
    [ceph_deploy.osd][DEBUG ] Listing disks on eayun-compute1...
    [eayun-compute1][INFO  ] Running command: ceph-disk list
    [eayun-compute1][DEBUG ] /dev/sda :
    [eayun-compute1][DEBUG ]  /dev/sda1 other, ext4, mounted on /
    [eayun-compute1][DEBUG ]  /dev/sda2 other, swap
    [eayun-compute1][DEBUG ] /dev/sdb other, unknown
    [eayun-compute1][DEBUG ] /dev/sdc other, unknown

>[root@eayun-admin ceph]# ceph-deploy disk zap eayun-compute1:/dev/sdb

    [ceph_deploy.cli][INFO  ] Invoked (1.3.5): /usr/bin/ceph-deploy disk zap eayun-compute1:/dev/sdb
    [ceph_deploy.osd][DEBUG ] zapping /dev/sdb on eayun-compute1
    [eayun-compute1][DEBUG ] connected to host: eayun-compute1 
    [eayun-compute1][DEBUG ] detect platform information from remote host
    [eayun-compute1][DEBUG ] detect machine type
    [ceph_deploy.osd][INFO  ] Distro info: CentOS 6.5 Final
    [eayun-compute1][DEBUG ] zeroing last few blocks of device
    [eayun-compute1][INFO  ] Running command: sgdisk --zap-all --clear --mbrtogpt -- /dev/sdb
    [eayun-compute1][DEBUG ] Creating new GPT entries.
    [eayun-compute1][DEBUG ] GPT data structures destroyed! You may now partition the disk using fdisk or
    [eayun-compute1][DEBUG ] other utilities.
    [eayun-compute1][DEBUG ] The operation has completed successfully.

>[root@eayun-admin ceph]# ceph-deploy disk prepare eayun-compute1:/dev/sdb

    [ceph_deploy.cli][INFO  ] Invoked (1.3.5): /usr/bin/ceph-deploy disk prepare eayun-compute1:/dev/sdb
    [ceph_deploy.osd][DEBUG ] Preparing cluster ceph disks eayun-compute1:/dev/sdb:
    [eayun-compute1][DEBUG ] connected to host: eayun-compute1 
    [eayun-compute1][DEBUG ] detect platform information from remote host
    [eayun-compute1][DEBUG ] detect machine type
    [ceph_deploy.osd][INFO  ] Distro info: CentOS 6.5 Final
    [ceph_deploy.osd][DEBUG ] Deploying osd to eayun-compute1
    [eayun-compute1][DEBUG ] write cluster configuration to /etc/ceph/{cluster}.conf
    [eayun-compute1][WARNIN] osd keyring does not exist yet, creating one
    [eayun-compute1][DEBUG ] create a keyring file
    [eayun-compute1][INFO  ] Running command: udevadm trigger --subsystem-match=block --action=add
    [ceph_deploy.osd][DEBUG ] Preparing host eayun-compute1 disk /dev/sdb journal None activate False
    [eayun-compute1][INFO  ] Running command: ceph-disk-prepare --fs-type xfs --cluster ceph -- /dev/sdb
    [eayun-compute1][WARNIN] INFO:ceph-disk:Will colocate journal with data on /dev/sdb
    [eayun-compute1][DEBUG ] Information: Moved requested sector from 34 to 2048 in
    [eayun-compute1][DEBUG ] order to align on 2048-sector boundaries.
    [eayun-compute1][DEBUG ] The operation has completed successfully.
    [eayun-compute1][DEBUG ] Information: Moved requested sector from 10485761 to 10487808 in
    [eayun-compute1][DEBUG ] order to align on 2048-sector boundaries.
    [eayun-compute1][DEBUG ] The operation has completed successfully.
    [eayun-compute1][DEBUG ] meta-data=/dev/sdb1              isize=2048   agcount=4, agsize=196543 blks
    [eayun-compute1][DEBUG ]          =                       sectsz=512   attr=2, projid32bit=0
    [eayun-compute1][DEBUG ] data     =                       bsize=4096   blocks=786171, imaxpct=25
    [eayun-compute1][DEBUG ]          =                       sunit=0      swidth=0 blks
    [eayun-compute1][DEBUG ] naming   =version 2              bsize=4096   ascii-ci=0
    [eayun-compute1][DEBUG ] log      =internal log           bsize=4096   blocks=2560, version=2
    [eayun-compute1][DEBUG ]          =                       sectsz=512   sunit=0 blks, lazy-count=1
    [eayun-compute1][DEBUG ] realtime =none                   extsz=4096   blocks=0, rtextents=0
    [eayun-compute1][DEBUG ] The operation has completed successfully.
    [ceph_deploy.osd][DEBUG ] Host eayun-compute1 is now ready for osd use.

>[root@eayun-admin ceph]# ceph-deploy disk list eayun-compute1

    [ceph_deploy.cli][INFO  ] Invoked (1.3.5): /usr/bin/ceph-deploy disk list eayun-compute1
    [eayun-compute1][DEBUG ] connected to host: eayun-compute1 
    [eayun-compute1][DEBUG ] detect platform information from remote host
    [eayun-compute1][DEBUG ] detect machine type
    [ceph_deploy.osd][INFO  ] Distro info: CentOS 6.5 Final
    [ceph_deploy.osd][DEBUG ] Listing disks on eayun-compute1...
    [eayun-compute1][INFO  ] Running command: ceph-disk list
    [eayun-compute1][DEBUG ] /dev/sda :
    [eayun-compute1][DEBUG ]  /dev/sda1 other, ext4, mounted on /
    [eayun-compute1][DEBUG ]  /dev/sda2 other, swap
    [eayun-compute1][DEBUG ] /dev/sdb :
    [eayun-compute1][DEBUG ]  /dev/sdb1 ceph data, active, cluster ceph, osd.0, journal /dev/sdb2
    [eayun-compute1][DEBUG ]  /dev/sdb2 ceph journal, for /dev/sdb1
    [eayun-compute1][DEBUG ] /dev/sdc :
    [eayun-compute1][DEBUG ]  /dev/sdc1 ceph data, active, cluster ceph, osd.1, journal /dev/sdc2
    [eayun-compute1][DEBUG ]  /dev/sdc2 ceph journal, for /dev/sdc1

>[root@eayun-admin ceph]# ceph-deploy disk activate eayun-compute1:/dev/sdb

    [ceph_deploy.cli][INFO  ] Invoked (1.3.5): /usr/bin/ceph-deploy disk activate eayun-compute1:/dev/sdb
    [ceph_deploy.osd][DEBUG ] Activating cluster ceph disks eayun-compute1:/dev/sdb:
    [eayun-compute1][DEBUG ] connected to host: eayun-compute1 
    [eayun-compute1][DEBUG ] detect platform information from remote host
    [eayun-compute1][DEBUG ] detect machine type
    [ceph_deploy.osd][INFO  ] Distro info: CentOS 6.5 Final
    [ceph_deploy.osd][DEBUG ] activating host eayun-compute1 disk /dev/sdb
    [ceph_deploy.osd][DEBUG ] will use init type: sysvinit
    [eayun-compute1][INFO  ] Running command: ceph-disk-activate --mark-init sysvinit --mount /dev/sdb
    
>[root@eayun-admin ceph]# ceph osd lspools

    0 data,1 metadata,2 rbd,

>[root@eayun-admin ceph]# ceph status
    
    cluster cfb2142b-32e2-41d2-9244-9c56bedd7846
     health HEALTH_WARN 192 pgs degraded; 192 pgs stuck unclean
     monmap e1: 1 mons at {eayun-admin=192.168.11.210:6789/0}, election epoch 1, quorum 0 eayun-admin
     osdmap e8: 2 osds: 2 up, 2 in
      pgmap v15: 192 pgs, 3 pools, 0 bytes data, 0 objects
            68372 kB used, 6055 MB / 6121 MB avail
                 192 active+degraded
...继续添加4个OSD，然后
>[root@eayun-admin ceph]# ceph status

    cluster cfb2142b-32e2-41d2-9244-9c56bedd7846
     health HEALTH_OK
     monmap e1: 1 mons at {eayun-admin=192.168.11.210:6789/0}, election epoch 1, quorum 0 eayun-admin
     osdmap e22: 6 osds: 6 up, 6 in
      pgmap v53: 192 pgs, 3 pools, 8 bytes data, 1 objects
            201 MB used, 18164 MB / 18365 MB avail
                 192 active+clean
>[root@eayun-admin ~(keystone_admin)]# ceph auth list

    installed auth entries:
    
    osd.0
            key: AQCy3DRTQF7TJBAAolYze6AHAhKb/aiYsP7i8Q==
            caps: [mon] allow profile osd
            caps: [osd] allow *
    osd.1
            key: AQDj3TRT6J9bKxAAWZHGH7ATaeqPv9Iw4hT3ag==
            caps: [mon] allow profile osd
            caps: [osd] allow *
    osd.2
            key: AQBk3zRTaFTHCBAAWb5M/2GaUbWg9sEBeeMsEQ==
            caps: [mon] allow profile osd
            caps: [osd] allow *
    osd.3
            key: AQCa3zRTyDI6IBAAWT28xyblxjJitBmxkcFhiA==
            caps: [mon] allow profile osd
            caps: [osd] allow *
    osd.4
            key: AQCk3zRTkKkFIBAAuu5Qbjv8IZt5sL9ro/mEzw==
            caps: [mon] allow profile osd
            caps: [osd] allow *
    osd.5
            key: AQCu3zRTsF5XIRAASdgzc8BfaRyLvc+bCH6rEQ==
            caps: [mon] allow profile osd
            caps: [osd] allow *
    client.admin
            key: AQBeOTRTcFaRLxAA48EyD2xpaq+jHfaAj1fdQg==
            caps: [mds] allow
            caps: [mon] allow *
            caps: [osd] allow *
    client.bootstrap-mds
            key: AQBfOTRToBYGJRAAw4PCsuWhj8HmrIjBE46k8g==
            caps: [mon] allow profile bootstrap-mds
    client.bootstrap-osd
            key: AQBfOTRTSJXQBhAABp3lUFkyxer7LYRNisDR/A==
            caps: [mon] allow profile bootstrap-osd


### next step to config ceph for openstack glance and cinder
>[root@eayun-admin ceph]# ceph osd pool create volumes 1000

    pool 'volumes' created
>[root@eayun-admin ceph]# ceph osd pool create images 1000

    pool 'images' created
    
>[root@eayun-admin ceph]# ceph auth get-or-create client.volumes mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rx pool=images'

    [client.volumes]
        key = AQCF6DRTOGGrEBAAnanwo1Qs5pONEGB2lCe49Q==
>[root@eayun-admin ceph]# ceph auth get-or-create client.images mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'

    [client.images]
        key = AQCU6DRTUH2GOBAA0fkbK3ANNqq9es/F0NXSyQ==
>[root@eayun-admin ceph(keystone_admin)]# ll

    -rw-r--r-- 1 root root    72 Mar 27 14:45 ceph.bootstrap-mds.keyring
    -rw-r--r-- 1 root root    72 Mar 27 14:45 ceph.bootstrap-osd.keyring
    -rw------- 1 root root    64 Mar 27 14:46 ceph.client.admin.keyring
    -rw-r--r-- 1 root root    64 Mar 28 03:54 ceph.client.images.keyring
    -rw-r--r-- 1 root root    65 Mar 28 06:08 ceph.client.volumes.keyring
    -rw-r--r-- 1 root root   343 Mar 28 02:42 ceph.conf
    -rw-r--r-- 1 root root 41044 Mar 28 02:34 ceph.log
    -rw-r--r-- 1 root root    73 Mar 27 14:31 ceph.mon.keyring
    -rwxr-xr-x 1 root root    92 Dec 20 22:47 rbdmap


copy ceph keyring to compute node(repeat this step on every compute node, fucking repeat!!!)
>[root@eayun-admin ceph]# ceph auth get-key client.volumes | ssh eayun-compute1|2|3 tee client.volumes.key
    
    AQCF6DRTOGGrEBAAnanwo1Qs5pONEGB2lCe49Q==
>[root@eayun-admin ~]# uuidgen #this uuid is also used by cinder.conf:rbd_secret_uuid!!!!
    
    a01a8859-8d0d-48de-8d03-d6f40cc40646
>[root@eayun-admin ceph]# ssh eayun-compute1

    [root@eayun-compute1 ~]# cat > secret.xml <<EOF  
    > <secret ephemeral='no' private='no'>
    >     <uuid>a01a8859-8d0d-48de-8d03-d6f40cc40646</uuid>
    >     <usage type='ceph'>  
    >         <name>client.volumes secret</name>
    >     </usage>
    > </secret>
    > EOF
>[root@eayun-compute1 ~]# virsh secret-define secret.xml 
    
    Secret c0bca24d-4648-500f-9590-0f934ad13572 created

>[root@eayun-compute1 ~]# virsh secret-set-value --secret {uuid of secret}  --base64 $(cat client.volumes.key) && rm client.volumes.key secret.xml

    Secret value set
    
    rm: remove regular file `client.volumes.key'? y
    rm: remove regular file `secret.xml'? y
>[root@eayun-compute1 ~]# virsh secret-list
    
    UUID                                 Usage
    -----------------------------------------------------------
    c0bca24d-4648-500f-9590-0f934ad13572 Unused

#### config glance to use ceph backend. 
>[root@eayun-admin ceph]# touch /etc/ceph/ceph.client.images.keyring

    [client.images]
        key = AQCU6DRTUH2GOBAA0fkbK3ANNqq9es/F0NXSyQ==
验证：rbd --id user-name ls pool-name
>[root@eayun-admin ceph]# rbd --id images ls images

    rbd: pool images doesn't contain rbd images
>[root@eayun-admin ceph]# vi /etc/glance/glance-api.conf

    default_store=rbd
    rbd_store_user=images
    rbd_store_pool=images
>[root@eayun-admin ceph]# /etc/init.d/openstack-glance-api restart

    Stopping openstack-glance-api:                             [  OK  ]
    Starting openstack-glance-api:                             [  OK  ]
>[root@eayun-admin ceph]# /etc/init.d/openstack-glance-registry restart

    Stopping openstack-glance-registry:                        [  OK  ]
    Starting openstack-glance-registry:                        [  OK  ]
上传一个模板
>[root@eayun-admin ceph]# rbd --id images ls images

    2bfbc891-b185-41a0-a373-655b5870babb
>[root@eayun-admin ~(keystone_admin)]# glance image-list

    +--------------------------------------+------------------------------+-------------+------------------+----------+--------+
    | ID                                   | Name                         | Disk Format | Container Format | Size     | Status |
    +--------------------------------------+------------------------------+-------------+------------------+----------+--------+
    | 2bfbc891-b185-41a0-a373-655b5870babb | cirros-0.3.1-x86_64-disk.img | qcow2       | bare             | 13147648 | active |
    +--------------------------------------+------------------------------+-------------+------------------+----------+--------+
#### config cinder to use ceph backend. 
>[root@eayun-admin ~(keystone_admin)]# vi /etc/cinder/cinder.conf

    volume_driver=cinder.volume.drivers.rbd.RBDDriver
    backup_ceph_conf=/etc/ceph/ceph.conf
    rbd_pool=volumes
    glance_api_version=2
    rbd_user=volumes
    rbd_secret_uuid={uuid of secret}
>[root@eayun-admin ~(keystone_admin)]# /etc/init.d/openstack-cinder-api restart  
>[root@eayun-admin ~(keystone_admin)]# /etc/init.d/openstack-cinder-scheduler restart  
>[root@eayun-admin ~(keystone_admin)]# /etc/init.d/openstack-cinder-volume restart

>[root@eayun-admin ceph]# rbd --id volumes ls volumes

    rbd: pool volumes doesn't contain rbd images
>[root@eayun-admin ~(keystone_admin)]# cinder create --display-name cinder-ceph-vol1 --display-description "first cinder volume on ceph backend" 1

    +---------------------+--------------------------------------+
    |       Property      |                Value                 |
    +---------------------+--------------------------------------+
    |     attachments     |                  []                  |
    |  availability_zone  |                 nova                 |
    |       bootable      |                false                 |
    |      created_at     |      2014-03-28T05:25:47.475149      |
    | display_description | first cinder volume on ceph backend  |
    |     display_name    |           cinder-ceph-vol1           |
    |          id         | a85c780a-9003-4bff-8271-5e200c9cad5e |
    |       metadata      |                  {}                  |
    |         size        |                  1                   |
    |     snapshot_id     |                 None                 |
    |     source_volid    |                 None                 |
    |        status       |               creating               |
    |     volume_type     |                 None                 |
    +---------------------+--------------------------------------+

>[root@eayun-admin cinder(keystone_admin)]# cinder list

    +--------------------------------------+-----------+--------------+------+-------------+----------+-------------+
    |                  ID                  |   Status  | Display Name | Size | Volume Type | Bootable | Attached to |
    +--------------------------------------+-----------+--------------+------+-------------+----------+-------------+
    | 59d0b231-f5a3-45d5-98a2-007319f65529 | available |  ceph-vol1   |  1   |     None    |  false   |             |
    +--------------------------------------+-----------+--------------+------+-------------+----------+-------------+
>[root@eayun-admin cinder(keystone_admin)]# rbd --id volumes ls volumes
    
    volume-59d0b231-f5a3-45d5-98a2-007319f65529

---
DEBUG
>[root@eayun-compute3 11008f92-d7bf-42d3-ac2c-acc2a54ffe9e]# virsh start instance-00000003

    error: Failed to start domain instance-00000003
    error: internal error Process exited while reading console log output: char device redirected to /dev/pts/0
    qemu-kvm: -drive file=rbd:volumes/volume-59d0b231-f5a3-45d5-98a2-007319f65529:id=libvirt:key=AQCF6DRTOGGrEBAAnanwo1Qs5pONEGB2lCe49Q==:auth_supported=cephx\;none:mon_host=192.168.11.210\:6789,if=none,id=drive-ide0-0-1: error connecting
    qemu-kvm: -drive file=rbd:volumes/volume-59d0b231-f5a3-45d5-98a2-007319f65529:id=libvirt:key=AQCF6DRTOGGrEBAAnanwo1Qs5pONEGB2lCe49Q==:auth_supported=cephx\;none:mon_host=192.168.11.210\:6789,if=none,id=drive-ide0-0-1: could not open disk image rbd:volumes/volume-59d0b231-f5a3-45d5-98a2-007319f65529:id=libvirt:key=AQCF6DRTOGGrEBAAnanwo1Qs5pONEGB2lCe49Q==:auth_supported=cephx\;none:mon_host=192.168.11.210\:6789: Operation not permitted
    //ceph.log
    2014-03-28 09:09:26.488788 7ffcd6eeb700  0 cephx server client.libvirt: couldn't find entity name: client.libvirt


---
###CEPH相关操作
####About Pool
To show a pool’s utilization statistics, execute:  
>[root@eayun-admin ceph]# rados df

    pool name       category                 KB      objects       clones     degraded      unfound           rd        rd KB           wr        wr KB
    data            -                          1            1            0            0           0           17           13            4            3
    images          -                          0            0            0            0           0            0            0            0            0
    metadata        -                          0            0            0            0           0            0            0            0            0
    rbd             -                          0            0            0            0           0            0            0            0            0
    volumes         -                          0            0            0            0           0            0            0            0            0
      total used          235868            1
      total avail       18570796
      total space       18806664  


>[root@eayun-admin ceph]# ceph osd pool get images size
    
    size: 3
>[root@eayun-admin ceph]# ceph osd pool get images pg_num
    
    pg_num: 1000
>[root@eayun-admin ceph]# ceph osd pool get images pgp_num
    
    pgp_num: 1000
>[root@eayun-admin ceph]# ceph osd pool set images pgp_num 99

    set pool 4 pgp_num to 99
>[root@eayun-admin ceph]# ceph osd pool set images pg_num 99
    
    specified pg_num 99 <= current 1000
不能把一个Pool的pg_num缩小！！！
>[root@eayun-admin ceph]# ceph osd pool get images pg_num

    pg_num: 1000
删除一个Pool. yes, i really really mean it :^)
>[root@eayun-admin ceph]# ceph osd pool delete images

    Error EPERM: WARNING: this will *PERMANENTLY DESTROY* all data stored in pool images.  If you are *ABSOLUTELY CERTAIN* that is what you want, pass the pool name *twice*, followed by --yes-i-really-really-mean-it.

>[root@eayun-admin ceph]# ceph osd pool delete images images --yes-i-really-really-mean-it

    pool 'images' deleted

Pool的ID是类似主键的自增序列，删除Pool重新创建后ID持续增加。
>[root@eayun-admin ceph]# ceph osd lspools

    0 data,1 metadata,2 rbd,5 images,6 volumes,
 
