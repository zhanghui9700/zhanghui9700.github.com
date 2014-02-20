Exec { timeout => 300 }


class {"mysql::server":
    config_hash => {bind_address => "0.0.0.0",
                    default_engine => "InnoDB",
                    root_password => "password",}
}

# deleting database users for security
# this is done in mysql::server::account_security but has problems
# when there is no fqdn, so we're defining a slightly different one here
database_user { [ 'root@127.0.0.1', 'root@::1', '@localhost', '@%' ]:
    ensure  => 'absent', require => Class['mysql::config'],
}
if ($::fqdn != "" and $::fqdn != "localhost") {
    database_user { [ "root@${::fqdn}", "@${::fqdn}"]:
        ensure  => 'absent', require => Class['mysql::config'],
    }
}
if ($::fqdn != $::hostname and $::hostname != "localhost") {
    database_user { ["root@${::hostname}", "@${::hostname}"]:
        ensure  => 'absent', require => Class['mysql::config'],
    }
}


class {"keystone::db::mysql":
    password      => "password",
    allowed_hosts => "%",
}

class {"glance::db::mysql":
    password      => "4bcdc3c7622d4555",
    allowed_hosts => "%",
}

# Create firewall rules to allow only the hosts that need to connect
# to mysql

$hosts = [ '192.168.176.134' ]

define add_allow_host {
    $source = $title ? {
        'ALL' => '0.0.0.0/0',
        default => $title,
    }
    firewall { "001 mysql incoming ${title}":
        proto  => 'tcp',
        dport  => ['3306'],
        action => 'accept',
        source => $source,
    }
}

add_allow_host {$hosts:}
