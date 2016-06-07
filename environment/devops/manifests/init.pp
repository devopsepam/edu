node default {
	notify { 'Integration test': }

	yumrepo { 'nginx':
		name => 'nginx',
		ensure => 'present',
		baseurl => 'http://nginx.org/packages/centos/7/$basearch/',
		gpgcheck => '0',
		enabled => '1',
	}

	php::ini { '/etc/php.ini':
	  display_errors => 'On',
	  memory_limit   => '256M',
	  date_timezone => 'Europe/Warsaw',
	}
	class { 'php::cli': }
	php::module { [ 'ldap', 'mysql', 'snmp', 'gd', 'xml' ]: }

	include '::php::fpm::daemon'
	php::fpm::conf { 'www':
  		listen  => '/var/run/php-fpm-www.sock',
	require => Package['nginx'],
	}

	class { '::nginx':
	# Fix for "upstream sent too big header ..." errors
		fastcgi_buffers     => '8 8k',
		fastcgi_buffer_size => '8k',
		autoindex => 'on',
		index => 'index.php',
		require => yumrepo['nginx'],
	}
	nginx::file { 'www.example.com.conf':
		content => template('nginx/www.example.com.conf.erb'),
	}

	file { '/var/www' :
		ensure => directory,
		owner => nginx,
		group => nginx,
		mode => 755,
	}
	file { '/var/www/www.example.com' :
		ensure => directory,
		owner => nginx,
		group => nginx,
		mode => 755,
	}
	file { '/var/www/www.example.com/index.php':
		source => 'puppet:///modules/nginx/index.php',
		owner => nginx,
		group => nginx,
	}
}
