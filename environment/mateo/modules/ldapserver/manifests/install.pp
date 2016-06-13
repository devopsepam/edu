class ldapserver::install (
	$ldap_packages = $ldapserver::params::ldap_packages,
	$ldap_services = $ldapserver::params::ldap_services,
	$ldap_pass = $ldapserver::params::ldap_password,
	) inherits ldapserver::params 
{
	package { "ldapserver::install::openldap_installation":
		name => "*openldap*",
		ensure => installed,
	}
	package { "ldapserver::install::migrationtools_installation":
                name => "migrationtools",
                ensure => installed,
        }
	file { '/var/lib/ldap/DB_CONFIG':
		ensure => present,
		owner => 'ldap',
		group => 'ldap',
		source => '/usr/share/openldap-servers/DB_CONFIG.example',
		path => '/var/lib/ldap/DB_CONFIG',
	}	
Package['ldapserver::install::openldap_installation'] ~> Package['ldapserver::install::migrationtools_installation'] -> File['/var/lib/ldap/DB_CONFIG']
}
