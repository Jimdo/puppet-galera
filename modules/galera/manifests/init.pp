class galera($cluster_name, $master_ip = false) {

    $mysql_user     = "wsrep_sst"
    $mysql_password = "password"

    service { "mysql-galera" :
        name        => "mysql",
        ensure      => "running",
        require     => [Package["mysql-server-wsrep","galera"],File["/etc/mysql/conf.d/wsrep.cnf","/etc/mysql/my.cnf"]],
        hasrestart  => true,
#        hasstatus   => true, // http://projects.puppetlabs.com/issues/5610
    }

    package { "mysql-client-5.1" :
        ensure      => present,
    }

    package { "mysql-server-wsrep" :
        ensure      => present,
        provider    => "dpkg",
        source      => "/tmp/mysql-server-wsrep-5.1.58-21.1-amd64.deb",
        require     => [Exec["download-wsrep"],Package["mysql-client-5.1"]],
    }

    exec { "download-wsrep" :
        command     => "wget -O /tmp/mysql-server-wsrep-5.1.58-21.1-amd64.deb http://launchpad.net/codership-mysql/5.1/5.1.58-21.1/+download/mysql-server-wsrep-5.1.58-21.1-amd64.deb",
        creates     => "/tmp/mysql-server-wsrep-5.1.58-21.1-amd64.deb"
    }

    package { "galera" :
        ensure      => present,
        provider    => "dpkg",
        source      => "/tmp/galera-21.1.0-amd64.deb",
        require     => [Exec["download-galera"],Package["mysql-client-5.1"]],
    }

    exec { "download-galera" :
        command     => "wget -O /tmp/galera-21.1.0-amd64.deb http://launchpad.net/galera/1.x/1.0/+download/galera-21.1.0-amd64.deb",
        creates     => "/tmp/galera-21.1.0-amd64.deb",
    }

    file { "/etc/mysql/conf.d/wsrep.cnf" :
        ensure      => present,
        content     => template("galera/wsrep.cnf.erb"),
        require     => Package["mysql-server-wsrep","galera"],
    }

    file { "/etc/mysql/my.cnf" :
        ensure      => present,
        content     => template("galera/my.cnf.erb"),
        require     => Package["mysql-server-wsrep","galera"],
    }
    exec { "set-mysql-password":
        unless      => "/usr/bin/mysql -u${mysql_user} -p${mysql_password}",
        command     => "/usr/bin/mysql -uroot -e \"set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to '${mysql_user}'@'%' identified by '${mysql_password}';flush privileges;\"",
        require     => Service["mysql-galera"],
        subscribe   => Service["mysql-galera"],
        refreshonly => true,
    }
}
