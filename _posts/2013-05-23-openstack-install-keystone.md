---
layout: post
title: openstack install keystone service
category: openstack
tags: [openstack, python]
---


### 1. 安装python基础依赖包

>   sudo apt-get install build-essential git python-dev python-setuptools python-pip libxml2-dev libxslt-dev

### 2. 安装mysql
>   sudo apt-get install mysql-server mysql-client python-mysqldb

### 3. 创建keystone数据框
>   mysql -u root <br />
>   create database keystone; <br />
>   grant all privileges on keystone.* to 'keystone'@'localhost' identified by 'password' with grant option; <br />
>   quit

### 4. 获取keystone/python-keystoneclient源代码
>   git clone git@github.com:openstack/keystone.git <br />
>   git clone git@github.com:openstack/python-keystoneclient.git

### 5. 安装keystone/python-keystoneclient
>   cd /opt/openstack/keystone <br />
>   sudo pip install -r tools/pip-requires <br />
>   sudo python setup.py install

>   其实这里并不是必须的，因为在keystone的pip-requires里已经包含python-keystoneclient， <br />
>   我们之所以要手动安装是因为，如果你要扩展keystone-api，那你就需要修改keystoneclient了。 <br />
>   cd /opt/openstack/python-keystoneclient <br />
>   sudo pip install -r tools/pip-requires <br />
>   sudo python setup.py install

### 6. 配置keystone
>   sudo mkdir /etc/keystone/ <br />
>   sudo cp ./etc/keystone.conf.sample /etc/keystone/keystone.conf <br />
>   vi /etc/keystone/keystone.conf
`connection = mysql://keystone:password@localhost/keystone`

### 7. Testing
>   export OS_SERVICE_TOKEN=ADMIN <br >
>   export OS_SERVICE_ENDPOINT='http://127.0.0.1:35357/v2.0'
#### 7.1. show all user, just test api if ok.
>   keystone user-list
    +----+------+---------+-------+
    | id | name | enabled | email |
    +----+------+---------+-------+
    +----+------+---------+-------+
#### 7.2. create tenant
>   keystone tenant-create --name demo --description "demo tenant" --enable true
    +-------------+----------------------------------+
    |   Property  |              Value               |
    +-------------+----------------------------------+
    | description |           demo tenant            |
    |   enabled   |               True               |
    |      id     | cae6a8e4472e46e9ac383d64c21a40ff |
    |     name    |               demo               |
    +-------------+----------------------------------+
#### 7.3. create user
>   keystone user-create --tenant-id cae6a8e4472e46e9ac383d64c21a40ff --name demo --pass password --enable true
    +----------+----------------------------------+
    | Property |              Value               |
    +----------+----------------------------------+
    |  email   |                                  |
    | enabled  |               True               |
    |    id    | b0a0b7f31e034352af3eb7ec637d4a91 |
    |   name   |               demo               |
    | tenantId | cae6a8e4472e46e9ac383d64c21a40ff |
    +----------+----------------------------------+
#### 7.4. create role
>   keystone role-create --name admin
    +----------+----------------------------------+
    | Property |              Value               |
    +----------+----------------------------------+
    |    id    | 8e88ac56af704ed7b2c1586fb41705a3 |
    |   name   |              admin               |
    +----------+----------------------------------+
#### 7.5. add user to role
>   keystone user-role-add --user b0a0b7f31e034352af3eb7ec637d4a91 --tenant-id cae6a8e4472e46e9ac383d64c21a40ff --role 8e88ac56af704ed7b2c1586fb41705a3
#### 7.6. show user role
>   keystone user-role-list --user demo --tenant demo
    +----------------------------------+----------+----------------------------------+----------------------------------+
    |                id                |   name   |             user_id              |            tenant_id             |
    +----------------------------------+----------+----------------------------------+----------------------------------+
    | 9fe2ff9ee4384b1894a90878d3e92bab | _member_ | b0a0b7f31e034352af3eb7ec637d4a91 | cae6a8e4472e46e9ac383d64c21a40ff |
    | 8e88ac56af704ed7b2c1586fb41705a3 |  admin   | b0a0b7f31e034352af3eb7ec637d4a91 | cae6a8e4472e46e9ac383d64c21a40ff |
    +----------------------------------+----------+----------------------------------+----------------------------------+
#### 7.7 user token
>   curl -d '{"auth":{"tenantName": "demo", "passwordCredentials": {"username": "demo", "password": "password"}}}' -H "Content-type: application/json" http://127.0.0.1:35357/v2.0/tokens | python -m json.tool
    {
        "access": {
            "metadata": {
                "is_admin": 0,
                "roles": [
                    "9fe2ff9ee4384b1894a90878d3e92bab",
                    "8e88ac56af704ed7b2c1586fb41705a3"
                ]
            },
            "serviceCatalog": [],
            "token": {
                "expires": "2013-05-22T18:37:47Z",
                "id": "xxxxxxxxx",
                "issued_at": "2013-05-21T18:37:47.487814",
                "tenant": {
                    "description": "demo tenant",
                    "enabled": true,
                    "id": "cae6a8e4472e46e9ac383d64c21a40ff",
                    "name": "demo"
                }
            },
            "user": {
                "id": "b0a0b7f31e034352af3eb7ec637d4a91",
                "name": "demo",
                "roles": [
                    {
                        "name": "_member_"
                    },
                    {
                        "name": "admin"
                    }
                ],
                "roles_links": [],
                "username": "demo"
            }
        }
    }

MAYBE:
Signing error: Unable to load certificate - ensure you've configured PKI with 'keystone-manage pki_setup'

---
\[参考资料\] <br />
[Openstack Hands on lab](http://liangbo.me/index.php/2012/03/27/11/)
