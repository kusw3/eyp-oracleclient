class oracleclient::sqlnet(
                            $invited_nodes,
                            $oraclehome  = '/u01/app/product/12/client',
                            $oracleuser  = 'oracle',
                            $oraclegroup = 'dba',
                            $names       = [ 'TZNAMES', 'LDAP', 'EZCONNECT' ],
                          ) inherits oracleclient::params {
  #

  validate_array($invited_nodes)

  file { "${oraclehome}/network/admin/sqlnet.ora":
    ensure  => 'present',
    owner   => $oracleuser,
    group   => $oraclegroup,
    mode    => '0644',
    content => template("${module_name}/sqlnet.erb"),
    require => Class['oracleclient'],
  }

}
