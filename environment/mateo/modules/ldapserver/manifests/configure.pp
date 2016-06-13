class ldapserver::configure (
		$ldap_pass = $ldapserver::params::ldap_password,
		$ldap_cont = $ldapserver::params::ldap_content,
		$ldif_dir = "/etc/openldap/slapd.d/cn=config",
		$ldap_dc1 = $ldapserver::params::ldap_dc_para1,
		$ldap_dc2 = $ldapserver::params::ldap_dc_para2,
		$ldap_dc3 = $ldapserver::params::ldap_dc_para3,
		$ldap_service = $ldapserver::params::ldap_services,
		$ldap_domain = $ldapserver::params::ldap_domain_path,
        	$certs_country = $ldapserver::params::cert_country,
        	$certs_state = $ldapserver::params::cert_state,
        	$certs_locality = $ldapserver::params::cert_locality,
        	$certs_organization = $ldapserver::params::cert_organization,
        	$certs_organizationalunit = $ldapserver::params::cert_organizationalunit,
        	$certs_email = $ldapserver::params::cert_email,
	) inherits ldapserver::params {
Exec['ldapserver::configure::set_ldap_password'] -> Exec['set_ldap_para'] -> Exec['fix_slashes'] -> Ldapserver::Configure::Root_line['ldapserver::configure::root_line'] -> Ldapserver::Configure::Access_line['access_line'] -> Ldapserver::Configure::Certs['certs'] -> Ldapserver::Configure::Certs2['certs2']
	exec { 'ldapserver::configure::set_ldap_password':
		command => "/usr/bin/rm -f /root/.templdap*; /usr/sbin/slappasswd -s ${ldap_pass} > /root/.templdap.random",
		path => "/usr/sbin/",
		#before => "fix_slashes",
	}
	exec { "set_ldap_para":
		command => "sed -i 's/olcSuffix.*/$ldap_dc1/g' $ldif_dir/olcDatabase\=\{2\}hdb.ldif; sed -i 's/olcRootDN.*/olcRootDN: $ldap_dc2/g' $ldif_dir/olcDatabase\=\{2\}hdb.ldif",	
		path => "/usr/bin/",
		#before => Exec['set_ldap_password'],
	}
	exec { "fix_slashes":
		command => "sed -i 's|\/|\\\/|g' /root/.templdap.random",
		path => "/bin/",
		require => Exec['ldapserver::configure::set_ldap_password'],
	}
	ldapserver::configure::root_line { "ldapserver::configure::root_line":
    		ldap_file => "$ldif_dir/olcDatabase\=\{2\}hdb.ldif",
    		ldap_file_line => "olcRootPW",
	}
	ldapserver::configure::access_line { "access_line":
    		ldap_access_file => "$ldif_dir/olcDatabase\=\{1\}monitor.ldif",
    		ldap_access_file_line => "olcAccess",
		ldap_access_path => "$ldap_dc2",
	}
        ldapserver::configure::certs { "certs":
                ldap_cert_file => "$ldif_dir/olcDatabase\=\{2\}hdb.ldif",
                ldap_cert_file_line => "olcTLSCertificateFile",
        }
        ldapserver::configure::certs2 { "certs2":
                ldap_cert_file => "$ldif_dir/olcDatabase\=\{2\}hdb.ldif",
                ldap_cert_file_line => "olcTLSCertificateKeyFile",
        }

###############################################
### /usr/share/migrationtools/migrate_common.ph
###############################################

	ldapserver::configure::migration_tool { "migration_tool":
                migr_file => "/usr/share/migrationtools/migrate_common.ph",
                migr_file_line => "DEFAULT_MAIL_DOMAIN",
		migr_path => $ldap_domain,
		migr_file_line2 => "DEFAULT_BASE",
		migr_path2 => $ldap_dc3,
		migr_file_line3 => "EXTENDED_SCHEMA",
        }

}

############################
### Definitions
############################

define ldapserver::configure::root_line ($ldap_file, $ldap_file_line) {
       		exec { "ldapserver::configure::root_line::root_change":
			command => 'sed -i "s/olcRootPW.*/olcRootPW: `cat \/root\/.templdap.random`/g" /etc/openldap/slapd.d/cn=config/olcDatabase\=\{2\}hdb.ldif',
			onlyif => "/bin/grep ${ldap_file_line} ${ldap_file}",
			require => Exec['fix_slashes'],
			path => "/bin/",
       		}	
		exec { "ldapserver::configure::root_line::root_new":
			command => "echo olcRootPW: `cat \/root\/.templdap.random` >> ${ldap_file}",
               		unless => "/bin/grep ${ldap_file_line} ${ldap_file}",
			path => "/bin/",
		}
}

define ldapserver::configure::access_line ($ldap_access_file, $ldap_access_file_line, $ldap_access_path) {
       		exec { "ldapserver::configure::access_line::access_line_change":
			command => "sed -i 's/olcAccess.*/olcAccess: {0}to \* by dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth\" read by dn.base=\"${ldap_access_path}\" read by \* none/g' /etc/openldap/slapd.d/cn=config/olcDatabase\=\{1\}monitor.ldif",
			onlyif => "/bin/grep ${ldap_access_file_line} ${ldap_access_file}",
			path => "/bin/",
       		}	
}

define ldapserver::configure::certs ($ldap_cert_file, $ldap_cert_file_line) {
		file { "ldapserver::configure::certs::make-selfsigned-script":
			path => '/etc/pki/tls/certs/make-dummy-ldap-cert',
        		content => template('ldapserver/make-dummy-ldap-cert.erb'),
		        ensure => file,
			mode => "0755",
   		}
		exec { "ldapserver::configure::certs::gen_cert":
			command => "/bin/bash /etc/pki/tls/certs/make-dummy-ldap-cert openldapself.pem",
			cwd => "/etc/pki/tls/certs/",
			path => ["/etc/pki/tls/certs/"],
			onlyif => "/usr/bin/test ! -f /etc/pki/tls/certs/openldapself.pem",
			require => File['ldapserver::configure::certs::make-selfsigned-script'],
		}
                exec { "ldapserver::configure::certs::use_cert":
                        command => 'sed -i "s/olcTLSCertificateFile.*/olcTLSCertificateFile: \/etc\/pki\/tls\/certs\/openldapself.pem/g" /etc/openldap/slapd.d/cn=config/olcDatabase\=\{2\}hdb.ldif',
                        onlyif => "/bin/grep ${ldap_cert_file_line} ${ldap_cert_file}",
                        path => "/bin/",
                }
                exec { "ldapserver::configure::certs::new_cert":
                        command => "echo olcTLSCertificateFile: \/etc\/pki\/tls\/certs\/openldapself.pem >> ${ldap_cert_file}",
                        unless => "/bin/grep ${ldap_cert_file_line} ${ldap_cert_file}",
                        path => "/bin/",
                }
}

define ldapserver::configure::certs2 ($ldap_cert_file, $ldap_cert_file_line) {
                exec { "ldapserver::configure::certs2::use_cert2":
                        command => 'sed -i "s/olcTLSCertificateKeyFile.*/olcTLSCertificateKeyFile: \/etc\/pki\/tls\/certs\/openldapself.pem/g" /etc/openldap/slapd.d/cn=config/olcDatabase\=\{2\}hdb.ldif',
                        onlyif => "/bin/grep ${ldap_cert_file_line} ${ldap_cert_file}",
                        path => "/bin/",
                }
                exec { "ldapserver::configure::certs2::new_cert2":
                        command => "echo olcTLSCertificateKeyFile: \/etc\/pki\/tls\/certs\/openldapself.pem >> ${ldap_cert_file}",
                        unless => "/bin/grep ${ldap_cert_file_line} ${ldap_cert_file}",
                        path => "/bin/",
                }
}

define ldapserver::configure::migration_tool ($migr_file, $migr_file_line, $migr_file_line2, $migr_file_line3, $migr_path, $migr_path2) {
                exec { "ldapserver::configure::migration_tool::migr_config_change1":
                        command => "sed -i 's|^\$DEFAULT_MAIL_DOMAIN.*|\$DEFAULT_MAIL_DOMAIN = \"${migr_path}\";|g' /usr/share/migrationtools/migrate_common.ph",
                        onlyif => "/bin/grep ${migr_file_line} ${migr_file}",
                        path => "/bin/",
                }
		exec { "ldapserver::configure::migration_tool::migr_config_change2":
                        command => "sed -i 's|^\$DEFAULT_BASE.*|\$DEFAULT_BASE = \"${migr_path2}\";|g' /usr/share/migrationtools/migrate_common.ph",
                        onlyif => "/bin/grep ${migr_file_line2} ${migr_file}",
                        path => "/bin/",
                }
                exec { "ldapserver::configure::migration_tool::migr_config_change3":
                        command => "sed -i 's|^\$EXTENDED_SCHEMA.*|\$EXTENDED_SCHEMA = 1;|g' /usr/share/migrationtools/migrate_common.ph",
                        onlyif => "/bin/grep ${migr_file_line3} ${migr_file}",
                        path => "/bin/",
                }
}
