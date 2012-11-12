
class galera(
    $cluster_name	  = 'galera', 
    $master_ip 		  = false,
    $mysql_user           = 'wsrep_sst',
    $mysql_password       = 'password',
    $root_password        = 'password',
    $old_root_password    = '',
    $etc_root_password    = false,
    $enabled              = true,
) {
   
   if $enabled {
    $service_ensure = 'running'
   } else {
    $service_ensure = 'stopped'
   }

   service { 'mysql-galera' :
        name        => "mysql",
        ensure      => $service_ensure,
        enable      => $enabled,
        require     => [Package["mysql-server-wsrep","galera","mysql-client-5.5","libaio1","libssl0.9.8"],File["/etc/mysql/conf.d/wsrep.cnf","/etc/mysql/my.cnf"]],
        hasrestart  => true,
	hasstatus   => true,
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

  # This kind of sucks, that I have to specify a difference resource for
  # restart.  the reason is that I need the service to be started before mods
  # to the config file which can cause a refresh
  exec { 'mysqld-restart':
    command     => "service mysql restart",
    logoutput   => on_failure,
    refreshonly => true,
    path        => '/sbin/:/usr/sbin/:/usr/bin/:/bin/',
  }

  # manage root password if it is set
  if $root_password != 'UNSET' {
    case $old_root_password {
      '':      { $old_pw='' }
      default: { $old_pw="-p${old_root_password}" }
    }

    exec { 'set_mysql_rootpw':
      command   => "mysqladmin -u root ${old_pw} password ${root_password}",
      logoutput => true,
      unless    => "mysqladmin -u root -p${root_password} status > /dev/null",
      path      => '/usr/local/sbin:/usr/bin:/usr/local/bin',
      notify    => Exec['mysqld-restart'],
      require   => [File['/etc/mysql/conf.d'],Service['mysql']],
    }

    file { '/root/.my.cnf':
      content => template('mysql/my.cnf.pass.erb'),
      require => Exec['set_mysql_rootpw'],
    }

    if $etc_root_password {
      file{ '/etc/my.cnf':
        content => template('mysql/my.cnf.pass.erb'),
        require => Exec['set_mysql_rootpw'],
      }
    }
 
    exec { "set-mysql-password-noroot" :
        unless      => "/usr/bin/mysql -u${mysql_user} -p${mysql_password}",
        command     => "/usr/bin/mysql -uroot -p -e \"set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to '${mysql_user}'@'%' identified by '${mysql_password}';flush privileges;\"",
        require     => Service["mysql"],
        subscribe   => Service["mysql"],
        refreshonly => true,
    }
  }

    exec { "set-mysql-password" :
        unless      => "/usr/bin/mysql -u${mysql_user} -p${mysql_password}",
        command     => "/usr/bin/mysql -uroot -p${root_password} -e \"set wsrep_on='off'; delete from mysql.user where user=''; grant all on *.* to '${mysql_user}'@'%' identified by '${mysql_password}';flush privileges;\"",
        require     => Service["mysql"],
        subscribe   => Service["mysql"],
        refreshonly => true,
    }

  file { '/etc/mysql':
    ensure => directory,
    mode   => '0755',
  }
  file { '/etc/mysql/conf.d':
    ensure => directory,
    mode   => '0755',
  }
  file { '/etc/my.cnf':
    content => template('galera/my.cnf.erb'),
    mode    => '0644',
  }

}
