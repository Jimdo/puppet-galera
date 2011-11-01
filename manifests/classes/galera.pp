class galera_node {

    require 'augeas'

    service { "mysql-galera" :
        ensure => "running",
        require => Package[mysql-server-wsrep],
        name => "mysql",
    }

    package { [ "mysql-client-5.1" ] :
        ensure => present
    }

    package { "mysql-server-wsrep" :
        ensure   => present,
        provider => "dpkg",
        source   => "/tmp/mysql-server-wsrep-5.1.58-21.1-amd64.deb",
        require  => [ Exec[download-wsrep], Package["mysql-client-5.1"] ]
    }

    exec { "download-wsrep" :
        command => "wget -O /tmp/mysql-server-wsrep-5.1.58-21.1-amd64.deb http://launchpad.net/codership-mysql/5.1/5.1.58-21.1/+download/mysql-server-wsrep-5.1.58-21.1-amd64.deb",
        creates => "/tmp/mysql-server-wsrep-5.1.58-21.1-amd64.deb"
    }

    package { "galera" :
        ensure   => present,
        provider => "dpkg",
        source   => "/tmp/galera-21.1.0-amd64.deb",
        require  => Exec[download-galera]
    }

    exec { "download-galera" :
        command => "wget -O /tmp/galera-21.1.0-amd64.deb http://launchpad.net/galera/1.x/1.0/+download/galera-21.1.0-amd64.deb",
        creates => "/tmp/galera-21.1.0-amd64.deb",
    }

#    file { "/etc/mysql/conf.d/wsrep.cnf" :
#        ensure => present,
#        source => "/tmp/vagrant-puppet/manifests/files/wsrep.cnf"
#    }


    augeas { "wsrep_provider":
        context => "/files/etc/mysql/conf.d/wsrep.cnf",
        changes => [
            "set wsrep_provider /usr/lib64/galera/libgalera_smm.so",
        ],
    }
}
