---
    # for all nodes
    sudo useradd -d /home/ceph -m ceph
    sudo passwd ceph
    echo "ceph ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph
    sudo chmod 0440 /etc/sudoers.d/ceph

---
    # admin-node node(ceph and root)
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

    sudo vim /etc/yum.repos.d/ceph.repo
    [ceph-noarch]
    name=Ceph noarch packages
    baseurl=http://ceph.com/rpm-dumpling/el6/noarch
    enabled=1
    gpgcheck=1
    type=rpm-md
    gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc

 ---
    # deploy
    mkdir -p /home/ceph/my-cluster & cd /home/ceph/my-cluster
    ceph-deploy new rdo-manager
    sudo ceph-deploy install rdo-manager rdo-compute1
    ceph-deploy mon create rdo-manager
    ceph-deploy gatherkeys rdo-manager
    sudo mkdir /var/local/osd0 (rdo-manager, rdo-compute1, this should be a partion or a full disk)
    sudo ceph-deploy osd prepare rdo-manager:/var/local/osd0 rdo-compute1:/var/local/osd1
    sudo ceph-deploy osd activate rdo-manager:/var/local/osd0 rdo-compute1:/var/local/osd1
    sudo ceph-deploy admin rdo-manager rdo-compute1
    sudo chmod +r /etc/ceph/ceph.client.admin.keyring
    ceph health
