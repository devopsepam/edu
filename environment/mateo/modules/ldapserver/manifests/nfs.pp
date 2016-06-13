class ldapserver::nfs (
                #$ldap_passw = $ldapserver::params::ldap_password,
		$nfs_packages = $ldapserver::params::nfs_pkg,
        ) inherits ldapserver::params {
        package { $nfs_packages:
                ensure => installed,
        }
        exec { "ldapserver::nfs::exports_table":
                command => "echo '/home *(rw,sync)' >> /etc/exports",
                path => ["/usr/bin/"],
                #require => Exec['ldapserver::schema::users_transform'],
                unless => '/bin/grep "home \*(rw,sync)" /etc/exports',
        }
        service { 'rpcbind_service_start':
                name => "rpcbind",
                ensure => "running",
                enable => true,
        }
        service { 'nfs_service_start':
                name => "nfs-server",
                ensure => "running",
                enable => true,
        }
}
