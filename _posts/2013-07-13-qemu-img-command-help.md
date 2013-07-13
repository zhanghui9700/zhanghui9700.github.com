---
layout: post
title: qemu-img command help
category: openstack
tags: [openstack, linux]
---

{% include JB/setup %}

    qemu-img -h
<br />
usage: qemu-img command \[command options\] <br />
QEMU disk image utility <br />
<br />
Command syntax: <br />
  check \[-f fmt\] \[-r \[leaks | all\]\] filename <br />
  **create** \[-f fmt\] \[-o options\] filename \[size\] <br />

    qemu-img create -f raw ./images/cirros.raw 1G
    >Formatting './images/cirros.raw', fmt=raw size=1073741824
    ll -h
    >-rw-r--r-- 1 root root 1.0G Jul 13 21:53 cirros.raw
    qemu-system-x86_64 /images/cirros.raw

    >backing_file
    qemu-img create -f qcow2 cirros_backing.qcow2 -o backing_file=cirros.raw 1G
    ll -h
    >-rw-r--r-- 1 root root 193K Jul 13 22:28 cirros_backing.qcow2
    qemu-img info cirros_backing.qcow2
    >image: cirros_backing.qcow2
    >file format: qcow2
    >virtual size: 1.0G (1073741824 bytes)
    >disk size: 196K
    >cluster_size: 65536
    >backing file: cirros.raw
    >使用backing_file创建的模板可以convert成raw格式，包含整个模板文件
    >这个convert将cirros_backing.qcow2和cirros.raw合并，生成新的raw格式模板
    qemu-img convert -O raw cirros_backing.qcow2 cirros_backing.raw
    qemu-img info cirros_backing.raw
    >image: cirros_backing.raw
    >file format: raw
    >virtual size: 1.0G (1073741824 bytes)
    >disk size: 0

  commit \[-f fmt\] \[-t cache\] filename <br />
  **convert** \[-c\] \[-p\] \[-f fmt\] \[-t cache\] \[-O output_fmt\] \[-o options\] \[-s snapshot_name\] \[-S sparse_size\] filename \[filename2 \[...\]\] output_filename <br />

    qemu-img convert -c -f raw -O qcow2 cirros.raw cirros.qcow2
    ll -h
    >-rw-r--r-- 1 root root 193K Jul 13 21:58 cirros.qcow2
    >-rw-r--r-- 1 root root 1.0G Jul 13 21:53 cirros.raw
    qemu-img convert -c -f raw -O qcow2 cirros.raw cirros.qcow2 -o ?
    >Supported options:
    >size             Virtual disk size
    >compat           Compatibility level (0.10 or 1.1)
    >backing_file     File name of a base image
    >backing_fmt      Image format of the base image
    >encryption       Encrypt the image
    >cluster_size     qcow2 cluster size
    >preallocation    Preallocation mode (allowed values: off, metadata)
    >lazy_refcounts   Postpone refcount updates

  **info** \[-f fmt\] \[--output=ofmt\] \[--backing-chain\] filename <br />

    qemu-img info cirros.raw
    >image: cirros.raw
    >file format: raw
    >virtual size: 1.0G (1073741824 bytes)
    >disk size: 0
    >虽然ll中看到文件的大小是1G，但是实际上磁盘大小是0。这就是稀疏文件
    qemu-img info cirros.qcow2
    >image: cirros.qcow2
    >file format: qcow2
    >virtual size: 1.0G (1073741824 bytes)
    >disk size: 136K
    >cluster_size: 65536

  snapshot \[-l | -a snapshot | -c snapshot | -d snapshot\] filename <br />

    >只有qcow2才支持快照
    qemu-img snapshot -l cirros.qcow2
    qemu-img snapshot -c tag1 cirros.qcow2
    qemu-img snapshot -c tag2 cirros.qcow2
    qemu-img snapshot -l cirros.qcow2
    >Snapshot list:
    >ID        TAG                 VM SIZE                DATE       VM CLOCK
    >1         tag1                      0 2013-07-13 22:14:31   00:00:00.000
    >2         tag2                      0 2013-07-13 22:15:31   00:00:00.000
    qemu-img snapshot -a 2 cirros.qcow2
    qemu-img snapshot -d 1 cirros.qcow2
    qemu-img snapshot -l cirros.qcow2
    >Snapshot list:
    >ID        TAG                 VM SIZE                DATE       VM CLOCK
    >2         tag2                      0 2013-07-13 22:15:31   00:00:00.000

  rebase \[-f fmt\] \[-t cache\] \[-p\] \[-u\] -b backing_file \[-F backing_fmt\] filename <br />
  **resize** filename \[+ | -\]size <br />

    >只有raw格式的镜像才可以改变大小
    qemu-img resize cirros.raw +1GB
    >Image resized.
    ll -h
    >-rw-r--r-- 1 root root 193K Jul 13 21:58 cirros.qcow2
    >-rw-r--r-- 1 root root 2.0G Jul 13 22:08 cirros.raw

<br />
Command parameters: <br />
   'filename' is a disk image filename <br />
   'fmt' is the disk image format. It is guessed automatically in most cases <br />
   'cache' is the cache mode used to write the output disk image, the valid options are: 'none', 'writeback' (default, except for convert), 'writethrough', 'directsync' and 'unsafe' (default for convert) <br />
   'size' is the disk image size in bytes. Optional suffixes 'k' or 'K' (kilobyte, 1024), 'M' (megabyte, 1024k), 'G' (gigabyte, 1024M) and T (terabyte, 1024G) are supported. 'b' is ignored.<br />
   'output_filename' is the destination disk image filename <br />
   'output_fmt' is the destination format <br />
   'options' is a comma separated list of format specific options in a name=value format. Use -o ? for an overview of the options supported by the used format <br />
   '-c' indicates that target image must be compressed (qcow format only) <br />
   '-u' enables unsafe rebasing. It is assumed that old and new backing file match exactly. The image doesn't need a working backing file before rebasing in this case (useful for renaming the backing file) <br />
   '-h' with or without a command shows this help and lists the supported formats <br />
   '-p' show progress of command (only certain commands) <br />
   '-S' indicates the consecutive number of bytes that must contain only zeros for qemu-img to create a sparse image during conversion <br />
   '--output' takes the format in which the output must be done (human or json) <br />
<br />
Parameters to check subcommand: <br />
   '-r' tries to repair any inconsistencies that are found during the check. '-r leaks' repairs only cluster leaks, whereas '-r all' fixes all kinds of errors, with a higher risk of choosing the wrong fix or hiding corruption that has already occurred. <br />
<br />
Parameters to snapshot subcommand:
   'snapshot' is the name of the snapshot to create, apply or delete <br />
   '-a' applies a snapshot (revert disk to saved state) <br />
   '-c' creates a snapshot <br />
   '-d' deletes a snapshot <br />
   '-l' lists all snapshots in the given image <br />
<br />
Supported formats: vvfat vpc vmdk vdi sheepdog raw host_cdrom host_floppy host_device file qed qcow2 qcow parallels nbd nbd nbd iscsi dmg tftp ftps ftp https http cow cloop bochs blkverify blkdebug
