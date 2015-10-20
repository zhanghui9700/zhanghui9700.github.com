---
layout: post
title: understand how openstack create instance disk
category: openstack
tags: [openstack]
---


>openstack 在创建虚拟机的过程中最后需要通过glance-image来创建虚拟机的disk文件，具体代码在/nova/virt/libvrit.py的_create_image中，这个创建过程说实话有点蛋疼，我感觉逻辑不是特别清晰，而且有些方法的命名也起到了很好的误导人的作用，所以只能猜测_create_image这个方法是一个做运维的兄弟写的:^)。这几天频繁的被一个同事吐槽，openstack架构太烂，各种烂，该耦合拆分了，该拆分的耦合了，各种不懂op的developer在做着devops的工作，结果就是不懂op的写代码，不懂写代码的最后负责op，最后让大家用来各种不顺手，所以就有了专门做openstack的服务的公司，而且还可以活的很大并且获得了大家认可，当然前提是在米国，在天朝，算了，还是开始分析一下这个create_image流程吧。


{% highlight python%}
# image_backend = Backend() #file at: /nova/virt/libvrit/imagebackend.py
# Backend().image() return Qcow2()
def image(fname, image_type=FLAGS.libvirt_images_type):
    return self.image_backend.image(instance['name'], fname + suffix, image_type)

# 这个root_fname 就是/var/lib/nova/instance/_base/<root_fname>那个cache文件名
# root_fname = hashlib.sha1(image_uuid).hexdigest()
image('disk').cache(fetch_func=libvirt_utils.fetch_image,
                    context=context,
                    filename=root_fname,
                    size=size,
                    image_id=disk_images['image_id'],
                    user_id=instance['user_id'],
                    project_id=instance['project_id'])


# 看一下cache方法：
def cache(self, fetch_func, filename, size=None, *args, **kwargs):
    """Creates image from template.

    Ensures that template and image not already exists.
    Ensures that base directory exists.
    Synchronizes on template fetching.

    :fetch_func: Function that creates the base image
                 Should accept `target` argument.
    :filename: Name of the file in the image directory
    :size: Size of created image in bytes (optional)
    """
    @utils.synchronized(filename, external=True, lock_path=self.lock_path)
    def call_if_not_exists(target, *args, **kwargs):
        if not os.path.exists(target):
            fetch_func(target=target, *args, **kwargs)

    if not os.path.exists(self.path):
        base_dir = os.path.join(FLAGS.instances_path, '_base')
        if not os.path.exists(base_dir):
            utils.ensure_tree(base_dir)
        base = os.path.join(base_dir, filename)

        self.create_image(call_if_not_exists, base, size,
                          *args, **kwargs)


# 再看看create_image方法：
class Qcow2(Image):
    def __init__(self, instance, name):
        super(Qcow2, self).__init__("file", "qcow2", is_block_dev=False)

        self.path = os.path.join(FLAGS.instances_path,
                                 instance, name)

    def create_image(self, prepare_template, base, size, *args, **kwargs):
        @utils.synchronized(base, external=True, lock_path=self.lock_path)
        def copy_qcow2_image(base, target, size):
            qcow2_base = base
            if size:
                size_gb = size / (1024 * 1024 * 1024)
                qcow2_base += '_%d' % size_gb
                if not os.path.exists(qcow2_base):
                    with utils.remove_path_on_error(qcow2_base):
                        libvirt_utils.copy_image(base, qcow2_base)
                        disk.extend(qcow2_base, size)
            libvirt_utils.create_cow_image(qcow2_base, target)

        prepare_template(target=base, *args, **kwargs)
        # NOTE(cfb): Having a flavor that sets the root size to 0 and having
        #            nova effectively ignore that size and use the size of the
        #            image is considered a feature at this time, not a bug.
        if size and size < disk.get_disk_size(base):
            LOG.error('%s virtual size larger than flavor root disk size %s' %
                      (base, size))
            raise exception.ImageTooLarge()
        with utils.remove_path_on_error(self.path):
            copy_qcow2_image(base, self.path, size)

{% endhighlight %}

    create_image的逻辑流程是这样子地：
    1. fetch_img from glance and save it to _base named to <cache_id>.part
    2. if img format not raw then run: qemu-img convert -O raw /var/lib/nova/instances/_base/<cache_id>.part /var/lib/nova/instances/_base/<cache_id>.converted
    3. rm <cache_id>.part
    4. rename <cache_id>.converted to <cache_id>
    5. copy_qcow2_img at _base: cp <cache_id> to <cache_id>_<root_disk_size>
    6. disk.extend(<cache_id>_<root_disk_size>, root_disk_size)
    7. create_cow_img: qemu-img create -f qcow2 -o backing_file=<cache_id>_<root_disk_size> /var/lib/nova/instances/instance-xxxxxxxx/disk

    因为有这个cache的关系，所以修改了模板后需要做两件事情
    1. 删除_base的下的cache，cache_id和image的对应关系如下：
        root_fname = hashlib.sha1(image_id).hexdigest()
    2. 修改数据库image对应的checksum，可以写个工作或者直接md5sum一下
        glance image-update <uuid> --checksum=xxxxxxxx

不过有时候md5sum算出来的好像和代码算出来的不一致，程序算image的checksum用的是如下方法(可以直接copy使用，不过我推荐自己写一遍，亲自动手openstack的代码是一个很好的学习过程，毕竟一个开源项目获得了太多优秀人才的贡献，多写一点以后可以做架构师啊，不过我是做总监的料)：

{% highlight python %}
#!/usr/bin/env python
#-*-coding=utf-8-*-


import hashlib
import sys


def chunkreadable(iter, chunk_size=65536):
    """
    Wrap a readable iterator with a reader yielding chunks of
    a preferred size, otherwise leave iterator unchanged.

    :param iter: an iter which may also be readable
    :param chunk_size: maximum size of chunk
    """
    return chunkiter(iter, chunk_size) if hasattr(iter, 'read') else iter


def chunkiter(fp, chunk_size=65536):
    """
    Return an iterator to a file-like obj which yields fixed size chunks

    :param fp: a file-like object
    :param chunk_size: maximum size of chunk
    """
    while True:
        chunk = fp.read(chunk_size)
        if chunk:
            yield chunk
        else:
            break


def cacl_md5(img_path):
    checksum = hashlib.md5()
    bytes_written = 0

    with open(img_path, 'r') as f:
        for buf in chunkreadable(f, 65536):
            bytes_written += len(buf)
            checksum.update(buf)

    checksum_hex = checksum.hexdigest()
    print "%s = %s" % (img_path, checksum_hex)
    return checksum_hex


def main(uuid):
    cacl_md5("/var/lib/glance/images/%s" % uuid)


if __name__ == "__main__":
    """usage: python glance-md5.py <image-uuid>"""
    main(sys.argv[1])

{% endhighlight%}

基本上create_image的流程算是简单了解了一下，其实我感觉openstack的网络才是最复杂的，现在我们还是用的VlanManager，但是我对iptables不太了解，不太懂NAT,SNAT各种，所以碰上浮动IP的问题，我有点不知道怎么调试，只能各种猜测(arp, tcpdump, tracepath)。
this all, done!

\[参考资料\] <br/>
[\[The life of an OpenStack libvirt image\]](http://www.pixelbeat.org/docs/openstack_libvirt_images/)
