---
layout: post
title: grow lvm file system and shrink lvm file system
category: linux
tag: [linux, openstack]
---

<a href="#shrink">[1]Shrink LVM File System</a>
<br />
<a href="#grow">[2]Grow LVM File System</a>

---

<a id="shrink"><h4>收缩分区空间</h4></a>

初始时候磁盘分区情况，/var/lib/nova/instances分区挂载在lv上,查看磁盘分区和lv信息。

    root@glos-manager:~# df -h
    Filesystem                                   Size  Used Avail Use% Mounted on
    /dev/mapper/cinder--volumes-system--root     3.7G  990M  2.6G  28% /
    udev                                         993M  4.0K  993M   1% /dev
    tmpfs                                        401M  352K  401M   1% /run
    none                                         5.0M     0  5.0M   0% /run/lock
    none                                        1002M     0 1002M   0% /run/shm
    /dev/sda1                                    184M   31M  145M  18% /boot
    /dev/sda3                                    939M   18M  875M   2% /home
    /dev/sda2                                    939M  524M  368M  59% /usr
    /dev/mapper/cinder--volumes-nova--instances  2.2G   68M  2.1G   4% /var/lib/nova/instances

    root@glos-manager:~# lvdisplay
      --- Logical volume ---
      LV Name                /dev/cinder-volumes/nova-instances
      VG Name                cinder-volumes
      LV UUID                IQCf3L-Zebu-CfrD-H5ct-qlg6-DnTI-SaQWef
      LV Write Access        read/write
      LV Status              available
      # open                 1
      LV Size                2.22 GiB
      Current LE             568
      Segments               1
      Allocation             inherit
      Read ahead sectors     auto
      - currently set to     256
      Block device           252:0

      --- Logical volume ---
      LV Name                /dev/cinder-volumes/system-root
      VG Name                cinder-volumes
      LV UUID                XVAGEN-Orq2-OnRI-FXvY-G3yd-dRiE-JdDlmw
      LV Write Access        read/write
      LV Status              available
      # open                 1
      LV Size                3.73 GiB
      Current LE             954
      Segments               1
      Allocation             inherit
      Read ahead sectors     auto
      - currently set to     256
      Block device           252:1

缩小lv的空间。

    umount /var/lib/nova/instances
    e2fsck -f /dev/mapper/cinder--volumes-nova--instances
    resize2fs /dev/mapper/cinder--volumes-nova--instances 1500M
    lvresize -L 1.5G /dev/cinder-volumes/nova-instances
    mount /dev/mapper/cinder--volumes-nova--instances /var/lib/nova/instances

查看缩小后的lv信息和磁盘分区情况。

    root@glos-manager:/# lvdisplay
      --- Logical volume ---
      LV Name                /dev/cinder-volumes/nova-instances
      VG Name                cinder-volumes
      LV UUID                IQCf3L-Zebu-CfrD-H5ct-qlg6-DnTI-SaQWef
      LV Write Access        read/write
      LV Status              available
      # open                 0
      LV Size                1.50 GiB
      Current LE             384
      Segments               1
      Allocation             inherit
      Read ahead sectors     auto
      - currently set to     256
      Block device           252:0

      --- Logical volume ---
      LV Name                /dev/cinder-volumes/system-root
      VG Name                cinder-volumes
      LV UUID                XVAGEN-Orq2-OnRI-FXvY-G3yd-dRiE-JdDlmw
      LV Write Access        read/write
      LV Status              available
      # open                 1
      LV Size                3.73 GiB
      Current LE             954
      Segments               1
      Allocation             inherit
      Read ahead sectors     auto
      - currently set to     256
      Block device           252:1

    root@glos-manager:/# mount /dev/mapper/cinder--volumes-nova--instances /var/lib/nova/instances
    root@glos-manager:/# df -h
    Filesystem                                   Size  Used Avail Use% Mounted on
    /dev/mapper/cinder--volumes-system--root     3.7G  990M  2.6G  28% /
    udev                                         993M  4.0K  993M   1% /dev
    tmpfs                                        401M  352K  401M   1% /run
    none                                         5.0M     0  5.0M   0% /run/lock
    none                                        1002M     0 1002M   0% /run/shm
    /dev/sda1                                    184M   31M  145M  18% /boot
    /dev/sda3                                    939M   18M  875M   2% /home
    /dev/sda2                                    939M  524M  368M  59% /usr
    /dev/mapper/cinder--volumes-nova--instances  1.5G   68M  1.4G   5% /var/lib/nova/instances

---

<a id="grow"><h4>扩展分区空间</h4></a>

查看磁盘分区情况和lv信息。

    root@glos-manager:/# lvdisplay
      --- Logical volume ---
      LV Name                /dev/cinder-volumes/nova-instances
      VG Name                cinder-volumes
      LV UUID                IQCf3L-Zebu-CfrD-H5ct-qlg6-DnTI-SaQWef
      LV Write Access        read/write
      LV Status              available
      # open                 1
      LV Size                1.50 GiB
      Current LE             384
      Segments               1
      Allocation             inherit
      Read ahead sectors     auto
      - currently set to     256
      Block device           252:0

      --- Logical volume ---
      LV Name                /dev/cinder-volumes/system-root
      VG Name                cinder-volumes
      LV UUID                XVAGEN-Orq2-OnRI-FXvY-G3yd-dRiE-JdDlmw
      LV Write Access        read/write
      LV Status              available
      # open                 1
      LV Size                3.73 GiB
      Current LE             954
      Segments               1
      Allocation             inherit
      Read ahead sectors     auto
      - currently set to     256
      Block device           252:1

    root@glos-manager:/# df -kh
    Filesystem                                   Size  Used Avail Use% Mounted on
    /dev/mapper/cinder--volumes-system--root     3.7G  990M  2.6G  28% /
    udev                                         993M  4.0K  993M   1% /dev
    tmpfs                                        401M  352K  401M   1% /run
    none                                         5.0M     0  5.0M   0% /run/lock
    none                                        1002M     0 1002M   0% /run/shm
    /dev/sda1                                    184M   31M  145M  18% /boot
    /dev/sda3                                    939M   18M  875M   2% /home
    /dev/sda2                                    939M  524M  368M  59% /usr
    /dev/mapper/cinder--volumes-nova--instances  1.5G   68M  1.4G   5% /var/lib/nova/instances

查看volume group的空间使用情况。

    root@glos-manager:/# vgdisplay cinder-volumes
      --- Volume group ---
      VG Name               cinder-volumes
      System ID
      Format                lvm2
      Metadata Areas        1
      Metadata Sequence No  4
      VG Access             read/write
      VG Status             resizable
      MAX LV                0
      Cur LV                2
      Open LV               2
      Max PV                0
      Cur PV                1
      Act PV                1
      VG Size               5.95 GiB
      PE Size               4.00 MiB
      Total PE              1522
      Alloc PE / Size       1338 / 5.23 GiB
      Free  PE / Size       184 / 736.00 MiB
      VG UUID               EIKfKf-mIvG-Sabt-JlV4-19Ot-XqSK-3dEXE0

还有700+MB可用，分配500MB到/var/lib/nova/instances空间。

    root@glos-manager:/# lvresize -L +500MB /dev/cinder-volumes/nova-instances
      Extending logical volume nova-instances to 1.99 GiB
      Logical volume nova-instances successfully resized

查看LV信息。

    root@glos-manager:/# lvdisplay
      --- Logical volume ---
      LV Name                /dev/cinder-volumes/nova-instances
      VG Name                cinder-volumes
      LV UUID                IQCf3L-Zebu-CfrD-H5ct-qlg6-DnTI-SaQWef
      LV Write Access        read/write
      LV Status              available
      # open                 1
      LV Size                1.99 GiB
      Current LE             509
      Segments               1
      Allocation             inherit
      Read ahead sectors     auto
      - currently set to     256
      Block device           252:0

      --- Logical volume ---
      LV Name                /dev/cinder-volumes/system-root
      VG Name                cinder-volumes
      LV UUID                XVAGEN-Orq2-OnRI-FXvY-G3yd-dRiE-JdDlmw
      LV Write Access        read/write
      LV Status              available
      # open                 1
      LV Size                3.73 GiB
      Current LE             954
      Segments               1
      Allocation             inherit
      Read ahead sectors     auto
      - currently set to     256
      Block device           252:1

查看磁盘分区情况。

    root@glos-manager:/# df -h
    Filesystem                                   Size  Used Avail Use% Mounted on
    /dev/mapper/cinder--volumes-system--root     3.7G  990M  2.6G  28% /
    udev                                         993M  4.0K  993M   1% /dev
    tmpfs                                        401M  352K  401M   1% /run
    none                                         5.0M     0  5.0M   0% /run/lock
    none                                        1002M     0 1002M   0% /run/shm
    /dev/sda1                                    184M   31M  145M  18% /boot
    /dev/sda3                                    939M   18M  875M   2% /home
    /dev/sda2                                    939M  524M  368M  59% /usr
    /dev/mapper/cinder--volumes-nova--instances  1.5G   68M  1.4G   5% /var/lib/nova/instances

instances分区依然保留原来1.5G分区，还需要对instances做扩展。

    root@glos-manager:/# resize2fs -p /dev/mapper/cinder--volumes-nova--instances
    resize2fs 1.42 (29-Nov-2011)
    Filesystem at /dev/mapper/cinder--volumes-nova--instances is mounted on /var/lib/nova/instances; on-line resizing required
    old_desc_blocks = 1, new_desc_blocks = 1
    Performing an on-line resize of /dev/mapper/cinder--volumes-nova--instances to 521216 (4k) blocks.
    The filesystem on /dev/mapper/cinder--volumes-nova--instances is now 521216 blocks long.

查看扩展后的效果。

    root@glos-manager:/# df -h
    Filesystem                                   Size  Used Avail Use% Mounted on
    /dev/mapper/cinder--volumes-system--root     3.7G  990M  2.6G  28% /
    udev                                         993M  4.0K  993M   1% /dev
    tmpfs                                        401M  352K  401M   1% /run
    none                                         5.0M     0  5.0M   0% /run/lock
    none                                        1002M     0 1002M   0% /run/shm
    /dev/sda1                                    184M   31M  145M  18% /boot
    /dev/sda3                                    939M   18M  875M   2% /home
    /dev/sda2                                    939M  524M  368M  59% /usr
    /dev/mapper/cinder--volumes-nova--instances  2.0G   68M  1.8G   4% /var/lib/nova/instances


-----
参考资料：
<br />
[\[LVM Resizing Guide \]](http://www.tcpdump.com/kb/os/linux/lvm-resizing-guide/all-pages.html)
