Exec { timeout => 300 }

exec { 'update-selinux-policy':
    path => "/usr/bin/",
    command => "yum update -y selinux-policy-targeted"
}
