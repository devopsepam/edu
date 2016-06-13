class ldapserver::schema (
                $ldap_passw = $ldapserver::params::ldap_password,
		$ldap_para2 = $ldapserver::params::ldap_dc_para2,
		$ldap_para3 = $ldapserver::params::ldap_dc_para3,
        ) inherits ldapserver::params {
File['ldapserver::schema::base_table'] -> User['ldapuser1'] ~> Exec['ldapserver::schema::ldapuser_users'] ~> Exec['ldapserver::schema::ldapuser_groups'] -> Exec['ldapserver::schema::users_transform'] -> Exec['ldapserver::schema::groups_transform'] -> Exec['ldapserver::schema::repair_monitor_file'] ~> Exec['ldapserver::schema::service_res'] -> Exec['ldapserver::schema::cosine_schema'] -> Exec['ldapserver::schema::inetorgperson_schema'] -> Exec['ldapserver::schema::nis_schema'] -> Exec['ldapserver::schema::add_base'] -> Exec['ldapserver::schema::add_users'] -> Exec['ldapserver::schema::add_groups']
	file { "ldapserver::schema::base_table":
        	path => '/root/.base.ldif',
                content => template('ldapserver/base.ldif.erb'),
                ensure => file,
                mode => "0660",
        }
	user { 'ldapuser1':
 		ensure           => 'present',
       		home             => '/home/ldapuser1',
       		password         => 'devops',
       		password_max_age => '99999',
       		password_min_age => '0',
       		shell            => '/bin/bash',
     	}
	exec { "ldapserver::schema::ldapuser_users":
		command => '/usr/bin/grep "ldapuser" /etc/passwd > /root/.temp_passwd',
                path => "/usr/bin/",
		#require => Exec['ldapserver::schema::add_base'],
	}
	exec { "ldapserver::schema::ldapuser_groups":
		command => '/usr/bin/grep "ldapuser" /etc/group > /root/.temp_group',
                path => "/usr/bin/",
		#require => Exec['ldapserver::schema::add_base'],
	}
        exec { "ldapserver::schema::users_transform":
        	command => "rm -f /root/users.ldif; /bin/perl /usr/share/migrationtools/migrate_passwd.pl /root/.temp_passwd /root/.users.ldif; rm -f /root/.temp_passwd",
                path => ["/bin/"],
		#require => Exec['ldapserver::schema::service_res'],
        }
        exec { "ldapserver::schema::groups_transform":
                command => "rm -f /root/groups.ldif; /bin/perl /usr/share/migrationtools/migrate_group.pl /root/.temp_group /root/.groups.ldif; rm -f /root/.temp_group",
                path => ["/bin/"],
		#require => Exec['ldapserver::schema::service_res'],
        }
	exec { "ldapserver::schema::service_res":
                command => "/usr/bin/systemctl restart slapd.service",
                path => ["/usr/bin/"],
                #require => Exec['ldapserver::schema::repair_monitor_file'],
        }
	exec { "ldapserver::schema::add_base":
		command => "ldapadd -x -w ${ldap_passw} -D '${ldap_para2}' -f /root/.base.ldif",
                path => ["/usr/bin/"],
		#require => Exec['ldapserver::schema::service_res'],
		unless => "/usr/bin/ldapsearch -x -b '${ldap_para3}' -s sub 'objectclass=*' | /bin/grep '# Devops,'",
	}
	exec { "ldapserver::schema::repair_monitor_file":
                command => "sed -i '/cn=Manager,dc=my-domain,dc=com/d' /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{1\}monitor.ldif",
                path => ["/usr/bin/"],
                #require => Ldapserver::Configure::Root_line['ldapserver::configure::root_line'],
                #require => Ldapserver::Configure::Root_line['ldapserver::configure::root_line'],
                onlyif => "/bin/grep 'cn=Manager,dc=my-domain,dc=com' /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{1\}monitor.ldif",
        }
	exec { "ldapserver::schema::nis_schema":
                command => "ldapadd -Y EXTERNAL -H ldapi:// -f /etc/openldap/schema/nis.ldif",
                path => ["/usr/bin/"],
                unless => "/usr/bin/ls /etc/openldap/slapd.d/cn\=config/cn\=schema/ | /usr/bin/grep nis.ldif",
        }
        exec { "ldapserver::schema::cosine_schema":
                command => "ldapadd -Y EXTERNAL -H ldapi:// -f /etc/openldap/schema/cosine.ldif",
                path => ["/usr/bin/"],
                unless => "/usr/bin/ls /etc/openldap/slapd.d/cn\=config/cn\=schema/ | /usr/bin/grep cosine.ldif",
        }
        exec { "ldapserver::schema::inetorgperson_schema":
                command => "ldapadd -Y EXTERNAL -H ldapi:// -f /etc/openldap/schema/inetorgperson.ldif",
                path => ["/usr/bin/"],
                unless => "/usr/bin/ls /etc/openldap/slapd.d/cn\=config/cn\=schema/ | /usr/bin/grep inetorgperson.ldif",
        }
        exec { "ldapserver::schema::add_users":
                command => "ldapadd -x -w ${ldap_passw} -D '${ldap_para2}' -f /root/.users.ldif",
                path => ["/usr/bin/"],
                #require => Exec['ldapserver::schema::users_transform'],
                unless => "/usr/bin/ldapsearch -x -b '${ldap_para3}' -s sub 'objectclass=*' | /bin/grep '# ldapuser1, People,'",
        }
        exec { "ldapserver::schema::add_groups":
                command => "ldapadd -x -w ${ldap_passw} -D '${ldap_para2}' -f /root/.groups.ldif",
                path => ["/usr/bin/"],
                #require => Exec['ldapserver::schema::groups_transform'],
                unless => "/usr/bin/ldapsearch -x -b '${ldap_para3}' -s sub 'objectclass=*' | /bin/grep '# ldapuser1, Group,'",
        }
}
