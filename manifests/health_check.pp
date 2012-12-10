#
# class galera::health_check provides in-depth monitoring of a MySQL Galera Node. 
# The class is meant to be used in conjunction with HAProxy.
# The class  has only been tested on Ubuntu 12.04 and HAProxy 1.4.18-0ubuntu1
#
# Requires augeas puppet module
#
# Here is an example HAProxy configuration that implements Galera health checking
#listen galera 192.168.220.40:3306
#  balance  leastconn
#  mode  tcp
#  option  tcpka
#  option  httpchk
#  server  control01 192.168.220.41:3306 check port 9200 inter 2000 rise 2 fall 5
#  server  control02 192.168.220.42:3306 check port 9200 inter 2000 rise 2 fall 5
#  server  control03 192.168.220.43:3306 check port 9200 inter 2000 rise 2 fall 5
#
# Example Usage:
#
# class {'galera::health_check': }
#
class galera::health_check(
  $mysql_host           = '127.0.0.1',
  $mysql_port           = '3306',
  $mysql_bin_dir        = '/usr/bin/mysql',
  $mysqlchk_script_dir  = '/usr/local/bin',
  $xinetd_dir 	        = '/etc/xinetd.d',
  $mysqlchk_user        = 'mysqlchk_user',
  $mysqlchk_password    = 'mysqlchk_password',
  $enabled              = true,
) {

  # Needed to manage /etc/services
  include augeas

  if $enabled {
    $service_ensure = 'running'
   } else {
    $service_ensure = 'stopped'
  }

  service { 'xinetd' :
    ensure      => $service_ensure,
    enable      => $enabled,
    require     => [Package['xinetd'],File["${xinetd_dir}/mysqlchk"]],
    subscribe   => File["${xinetd_dir}/mysqlchk"],
  }

  package { 'xinetd':
    ensure  => present,
    require => Package["mysql-server-wsrep","galera","mysql-client-5.5"],
  }

  file { $mysqlchk_script_dir:
    ensure  => directory,
    mode    => '0755',
    require => Package['xinetd'],
    owner   => 'root',
    group   => 'root',
  }

  file { $xinetd_dir:
    ensure  => directory,
    mode    => '0755',
    require => Package['xinetd'],
    owner   => 'root',
    group   => 'root',
  }

  file { "${mysqlchk_script_dir}/galera_chk":
    mode    => '0755',
    require => File[$mysqlchk_script_dir],
    content => template("galera/galera_chk"),
    owner   => 'root',
    group   => 'root',
  }

  file { "${xinetd_dir}/mysqlchk":
    mode    => '0644',
    require => File[$xinetd_dir],
    content => template("galera/mysqlchk"),
    owner   => 'root',
    group   => 'root',  
  }

  # Manage mysqlchk service in /etc/services
  augeas { "mysqlchk":
    require => File["${xinetd_dir}/mysqlchk"],
    context =>  "/files/etc/services",
    changes => [
      "ins service-name after service-name[last()]",
      "set service-name[last()] mysqlchk",
      "set service-name[. = 'mysqlchk']/port 9200",
      "set service-name[. = 'mysqlchk']/protocol tcp",
    ],  
    onlyif => "match service-name[port = '9200'] size == 0",
  }

  # Create a user for script to use for checking MySQL health status.
  galera::db { 'mysql':
    user     => $mysqlchk_user,
    password => $mysqlchk_password,
    host     => $mysql_host,
    grant    => ['all']
  }
}
