
class galera($cluster_name, $master_ip = false) {

    $mysql_user           = "wsrep_sst"
    $mysql_password       = "password"

    service { "mysql-galera" :
        name        => "mysql",
        ensure      => "running",
        require     => [Package["mysql-server-wsrep","galera","mysql-client-5.5","libaio1","libssl0.9.8"],File["/etc/mysql/conf.d/wsrep.cnf","/etc/mysql/my.cnf"]],
        hasrestart  => true,
	hasstatus   => true,
#       hasstatus   => true, // http://projects.puppetlabs.com/issues/5610
    }

    package { "mysql-client-5.5" :
        ensure      => present,
    }

    package { "libaio1" :
        ensure      => present,
    }

    package { "libssl0.9.8" :
        ensure      => present,
    }

    package { "mysql-server-wsrep" :
        ensure      => present,
        provider    => "dpkg",
        source      => "/tmp/mysql-server-wsrep-5.5.23-23.6-amd64.deb",
        require     => [Exec["download-wsrep"],Package["mysql-client-5.5","libaio1","libssl0.9.8"]],
    }

    package { "galera" :
        ensure      => present,
        provider    => "dpkg",
        source      => "/tmp/galera-23.2.1-amd64.deb",
        require     => [Exec["download-galera"],Package["mysql-client-5.5","libaio1","libssl0.9.8"]],
    }

    exec { "download-wsrep" :
        command     => "wget -O /tmp/mysql-server-wsrep-5.5.23-23.6-amd64.deb http://launchpad.net/codership-mysql/5.5/5.5.23-23.6/+download/mysql-server-wsrep-5.5.23-23.6-amd64.deb",
        path        => '/usr/bin:/usr/sbin:/bin:/sbin',
	creates     => "/tmp/mysql-server-wsrep-5.5.23-23.6-amd64.deb",
    }

    exec { "download-galera" :
        command     => "wget -O /tmp/galera-23.2.1-amd64.deb http://launchpad.net/galera/2.x/23.2.1/+download/galera-23.2.1-amd64.deb",
        path        => '/usr/bin:/usr/sbin:/bin:/sbin',
	creates     => "/tmp/galera-23.2.1-amd64.deb",
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

    exec { "set-mysql-password" :
        unless      => "/usr/bin/mysql -u${mysql_user} -p${mysql_password}",
        command     => "/usr/bin/mysql -uroot -e \"set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to '${mysql_user}'@'%' identified by '${mysql_password}';flush privileges;\"",
        require     => Service["mysql-galera"],
        subscribe   => Service["mysql-galera"],
        refreshonly => true,
    }
}
