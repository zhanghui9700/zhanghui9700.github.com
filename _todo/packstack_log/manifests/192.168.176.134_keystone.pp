Exec { timeout => 300 }


class {"keystone":
    admin_token => "293d9a1142ff475cbe92eea1d0bd1e6a",
    sql_connection => "mysql://keystone_admin:password@192.168.176.134/keystone",
    token_format => "PKI",
    verbose => true,
    debug => false,
}

class {"keystone::roles::admin":
    email => "test@test.com",
    password => "password",
    admin_tenant => "admin"
}

class {"keystone::endpoint":
    public_address  => "192.168.176.134",
    admin_address  => "192.168.176.134",
    internal_address  => "192.168.176.134",
}

# Run token flush every minute (without output so we won't spam admins)
cron { 'token-flush':
    ensure => 'present',
    command => '/usr/bin/keystone-manage token_flush >/dev/null 2>&1',
    minute => '*/1',
} -> service { 'crond':
    ensure => 'running',
    enable => true,
}
# Create firewall rules to allow only the hosts that need to connect
# to keystone

$hosts = [ 'ALL' ]

define add_allow_host {
    $source = $title ? {
        'ALL' => '0.0.0.0/0',
        default => $title,
    }
    firewall { "001 keystone incoming ${title}":
        proto  => 'tcp',
        dport  => ['5000', '35357'],
        action => 'accept',
        source => $source,
    }
}

add_allow_host {$hosts:}


class {"glance::keystone::auth":
    password => "1e488be476574bfa",
    public_address => "192.168.176.134",
    admin_address => "192.168.176.134",
    internal_address => "192.168.176.134",
}
