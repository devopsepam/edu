class ldapserver {
	include ldapserver::install
	include ldapserver::configure
	include ldapserver::schema
	include ldapserver::nfs
	include ldapserver::fusion
	Class['ldapserver::install'] -> Class['ldapserver::configure'] -> Class['ldapserver::schema'] -> Class['ldapserver::fusion'] -> Class['ldapserver::nfs']
} 
