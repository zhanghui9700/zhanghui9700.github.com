Exec { timeout => 300 }


$clientdeps = ["python-iso8601"]
package { $clientdeps: }

$clientlibs = ["python-novaclient", "python-keystoneclient", "python-glanceclient", "python-swiftclient", "python-cinderclient"]
package { $clientlibs: }

$rcadmin_content = "export OS_USERNAME=admin
export OS_TENANT_NAME=admin
export OS_PASSWORD=password
export OS_AUTH_URL=http://192.168.176.134:35357/v2.0/
export PS1='[\\u@\\h \\W(keystone_admin)]\\$ '
"

file {"${::home_dir}/keystonerc_admin":
   ensure  => "present",
   mode => '0600',
   content => $rcadmin_content,
}

if 'n' == 'y' {
   file {"${::home_dir}/keystonerc_demo":
      ensure  => "present",
      mode => '0600',
      content => "export OS_USERNAME=demo
export OS_TENANT_NAME=demo
export OS_PASSWORD=password
export OS_AUTH_URL=http://192.168.176.134:35357/v2.0/
export PS1='[\\u@\\h \\W(keystone_demo)]\\$ '
",
   }
}

if false {
    file {"/root/keystonerc_admin":
       ensure => present,
       owner => 'vagrant',
       group => 'vagrant',
       mode => '0600',
       content => $rcadmin_content,
    }
}
