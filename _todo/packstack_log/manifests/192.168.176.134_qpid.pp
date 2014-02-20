Exec { timeout => 300 }

$enable_auth = 'n'

class {"qpid::server":
    config_file => $::operatingsystem? {
        'Fedora' => '/etc/qpid/qpidd.conf',
        default  => '/etc/qpidd.conf',
        },
    auth => $enable_auth ? {
        'y'  => 'yes',
        default => 'no',
        },
    clustered => false,
    ssl_port      => '5671',
    ssl           => false,
    ssl_cert      => '',
    ssl_key       => '',
    ssl_database_password => '',
}
# Create firewall rules to allow only the hosts that need to connect
# to qpid

$hosts = [ '192.168.176.134' ]

define add_allow_host {
    $source = $title ? {
        'ALL' => '0.0.0.0/0',
        default => $title,
    }
    firewall { "001 qpid incoming ${title}":
        proto  => 'tcp',
        dport  => ['5671', '5672'],
        action => 'accept',
        source => $source,
    }
}

add_allow_host {$hosts:}
