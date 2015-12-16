class oracleclient::ldap(
                            $directory_servers,
                            $directory_admin_context,
                            $directory_server_type= 'OID',
                            $oraclehome='/u01/app/product/12/client',
                            $oracleuser='oracle',
                            $oraclegroup='dba',
                          ) inherits oracleclient::params {
  #
  file { "${oraclehome}/network/admin/ldap.ora":
    ensure  => 'present',
    owner   => $oracleuser,
    group   => $oraclegroup,
    mode    => '0644',
    content => template("${module_name}/ldap.erb"),
    require => Class['oracleclient'],
  }

}
