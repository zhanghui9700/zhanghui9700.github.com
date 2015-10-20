---
layout: post
category: openstack
title: revovery openstack instance
tags: [linux, openstack]
---



在不能进行live-migeration或者block-migeration的情况下，客户需要将一个负载比较高的云主机迁移到负载比较低的物理服务器

现在整理一下手动迁移云主机的步骤，经验证实施成功，具体操作：

    1. 释放浮动IP
    2. 关闭云主机，记录云主机UUID，instance-00000xxx

    源物理机
    3. virsh undefine instance-000000xx
    4. scp -r instance-000000xx eayun@xxx.xxx.xxx.xxx:/tmp

    目标物理机
    5.  cd /var/lib/nova/instances
    6. mv /tmp/instance-000000xx /var/lib/nova/instances
    7. cd instance-000000xx
    8. vi libvirt.xml
    <parameter name="DHCPSERVER" value="172.16.0.4"/>
    修改DHCPSERVER 为正确的dhcpserver地址，查看其他同项目云主机配置即可
    9.  查看libvirt.xml 中  <filterref filter="nova-instance-instance-00000015-fa163e6b0c0b">的值
    10. vi nw.xml
    <filter name="nova-instance-instance-00000015-fa163e6b0c0b" chain="root" >
    <filterref filter="nova-base" />
    </filter>
    11. virsh nwfilter-define nw.xml
    12. virsh define libvirt.xml
    13. mysql -uroot -peayun2012
    use nova;
    update instances set host='target-hostname' where uuid = 'xxxx';
    14.service nova-network restart

    15. 开启云主机
    16. 绑定浮动IP

