class ldapserver::params
{
	$ldap_packages = ["*openldap*", "migrationtools"]
	$ldap_services = ["slapd"]
	$ldap_password = "devops"
	$ldap_dc_para1 = "olcSuffix: dc=dev,dc=com"
	$ldap_dc_para2 = "cn=Devops,dc=dev,dc=com"
	$ldap_dc_para3 = "dc=dev,dc=com"
	$nfs_pkg = ["rpcbind", "nfs-utils"]
	$ldap_domain_path = "dev.com"
	$cert_country = "GB"
	$cert_state = "Nottingham"
	$cert_locality = "Nottinghamshire"
	$cert_organization = "Jamescoyle.net"
	$cert_organizationalunit = "IT"
	$cert_email = "administrator@jamescoyle.net"
}
