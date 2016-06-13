node default {
	notify { 'Integration test': }

	yumrepo { 'nginx':
		name => 'nginx',
		ensure => 'present',
		baseurl => 'http://nginx.org/packages/centos/7/$basearch/',
		gpgcheck => '0',
		enabled => '1',
    before => Package['nginx'],
	}
  	yumrepo { 'epel':
	    name => 'epel',
	    ensure => 'present',
	    mirrorlist => 'https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
	    failovermethod => 'priority',
	    gpgcheck => '0',
	    enabled => '1',
	before => Package['phpmyadmin'],
	}
  
	php::ini { '/etc/php.ini':
	  display_errors => 'On',
	  memory_limit   => '256M',
	  date_timezone => 'Europe/Warsaw',
	}
	class { 'php::cli': }
	php::module { [ 'ldap', 'mysql', 'snmp', 'gd', 'xml', 'mbstring' ]: }

	include '::php::fpm::daemon'
	php::fpm::conf { 'www':
  		listen  => '/var/run/php-fpm-www.sock',
	}
  
	class { '::nginx':
	# Fix for "upstream sent too big header ..." errors
		fastcgi_buffers     => '8 8k',
		fastcgi_buffer_size => '8k',
		autoindex => 'on',
		index => 'index.php',
	}
	nginx::file { 'www.devops.com.conf':
		content => template('nginx/www.devops.com.conf.erb'),
	}

  file { '/var/www' :
		ensure => directory,
		owner => apache,
		group => apache,
  	mode => 755,
    subscribe => Package['nginx'],
	}
	file { '/var/www/www.devops.com' :
		ensure => directory,
		owner => apache,
		group => apache,
		mode => 755,
    subscribe => Package['nginx'],
	}
	file { '/var/www/www.devops.com/index.php':
		source => 'puppet:///modules/nginx/index.php',
		owner => apache,
		group => apache,
    subscribe => Package['nginx'],
	}

  package { 'phpmyadmin':
    ensure => installed,
    provider => 'yum',
    alias => 'phpmyadmin',
  }
  file { '/var/www/www.devops.com/pma/':
    ensure => link,
    target => '/usr/share/phpMyAdmin/',
    subscribe => Package['phpmyadmin'],
  }
# fix sessions issue for phpMyAdmin
  file { '/var/lib/php/session':
    ensure => directory,
    mode => 755,
    owner => apache,
    subscribe => Package['php-fpm'],
  }

  hello::file {'hello.php':
#  		content => template('hello/hello.php.erb'),
  		owner => apache,
  		subscribe => Package['php-fpm'],
  	}
}
