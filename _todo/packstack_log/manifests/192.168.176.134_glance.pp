Exec { timeout => 300 }


class {"glance::api":
    auth_host => "192.168.176.134",
    keystone_tenant => "services",
    keystone_user => "glance",
    keystone_password => "1e488be476574bfa",
    pipeline => 'keystone',
    sql_connection => "mysql://glance:4bcdc3c7622d4555@192.168.176.134/glance",
    verbose => true,
    debug => false,
}

class { 'glance::backend::file': }

class {"glance::registry":
    auth_host => "192.168.176.134",
    keystone_tenant => "services",
    keystone_user => "glance",
    keystone_password => "1e488be476574bfa",
    sql_connection => "mysql://glance:4bcdc3c7622d4555@192.168.176.134/glance",
    verbose => true,
    debug => false,
}
# Create firewall rules to allow only the hosts that need to connect
# to glance

$hosts = [ 'ALL' ]

define add_allow_host {
    $source = $title ? {
        'ALL' => '0.0.0.0/0',
        default => $title,
    }
    firewall { "001 glance incoming ${title}":
        proto  => 'tcp',
        dport  => ['9292'],
        action => 'accept',
        source => $source,
    }
}

add_allow_host {$hosts:}
