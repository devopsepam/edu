class ldapserver::fusion (
                #$ldap_passw = $ldapserver::params::ldap_password,
        ) inherits ldapserver::params {
	file { "fusion_repository":
		path => "/etc/yum.repos.d/fusiondirectory.repo",
		content => template('ldapserver/fusiondirectory.repo.erb'),
	}
        file { "fusion-extra_repository":
                path => "/etc/yum.repos.d/fusiondirectory-extra.repo",
                content => template('ldapserver/fusiondirectory-extra.repo.erb'),
        }
	yumrepo { 'epel_repository':
	    #name => 'epel',
	    ensure => 'present',
	    mirrorlist => 'https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
	    failovermethod => 'priority',
	    gpgcheck => '0',
	    enabled => '1',
	before => Package['fusion_dependencies'],
	}
	package { "fusion_dependencies":
                name => "php-pear-MDB2",
                ensure => installed,
	}
	package { "fusion_installation":
		name => "fusiondirectory",
                ensure => installed,
                require => Package['ldapserver::install::openldap_installation'],
	}
        package { "fusion-schema_installation":
                name => "fusiondirectory-schema",
                ensure => installed,
                require => Package['fusion_installation'],
        }
        package { "schema2ldif_installation":
                name => "schema2ldif",
                ensure => installed,
                require => Package['fusion-schema_installation'],
        }
	package { "fusion-selinux_installation":
                name => "fusiondirectory-selinux",
                ensure => installed,
                require => Package['schema2ldif_installation'],
        }
        exec { "ldapserver::fusion::insert-schema":
                command => "/usr/sbin/fusiondirectory-insert-schema",
                path => ["/usr/bin/"],
                require => Package['schema2ldif_installation'],
                unless => "/usr/sbin/fusiondirectory-insert-schema -l |grep core-fd",
        }
        exec { "ldapserver::fusion::check-fusion-schema":
                command => "/usr/sbin/fusiondirectory-setup --check-directories --update-cache --update-locales; chgrp -R apache /var/cache/fusiondirectory/*; chmod g+rw /var/cache/fusiondirectory/class.cache",
                path => ["/usr/bin/"],
                require => Exec['ldapserver::fusion::insert-schema'],
        }
        exec { "ldapserver::fusion::PHP_security":
		command => 'sed -i "s/^expose_php = On$/expose_php = Off/g" /etc/php.ini',
                onlyif => "/bin/grep expose_php /etc/php.ini",
                path => "/bin/",
        }
        exec { "ldapserver::fusion::blank_creation":
                command => "/usr/bin/touch /var/cache/fusiondirectory/template/fusiondirectory.conf; /usr/bin/chgrp apache /var/cache/fusiondirectory/template/fusiondirectory.conf; /usr/bin/chmod g+rw /var/cache/fusiondirectory/template/fusiondirectory.conf",
                path => ["/usr/bin/"],
                require => Exec['ldapserver::fusion::check-fusion-schema'],
		onlyif => "/usr/bin/test ! -f /var/cache/fusiondirectory/template/fusiondirectory.conf",
        }
	exec { "ldapserver::fusion::httpd_start":
                command => "/usr/bin/systemctl start httpd",
                path => ["/usr/bin/"],
                require => Exec['ldapserver::fusion::blank_creation'],
        }
}
