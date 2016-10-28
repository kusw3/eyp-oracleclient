class oracleclient  (
                      $package             = undef,
                      $localfile           = undef,
                      $exactversion        = '12.1.0.1.0',
                      $oracleuser          = 'oracle',
                      $oraclegroup         = 'dba',
                      $oracleinstallgroup  = 'oinstall',
                      $oraclehome          = '/u01/app/product/12/client',
                      $oraclebase          = '/u01/app',
                      $orainventory        = '/u01/app/oraInventory',
                      $srcdir              = '/u01/software',
                      $languages           = [ 'en' ],
                      $createusers         = true,
                      $addtopath           = false,
                      $software_to_install = [ 'oracle.rdbms.util', 'oracle.javavm.client', 'oracle.sqlplus',
                                              'oracle.dbjava.jdbc', 'oracle.network.client', 'oracle.odbc' ],
                    )inherits params {

  validate_array($languages)

  validate_absolute_path($oraclehome)
  validate_absolute_path($oraclebase)
  validate_absolute_path($orainventory)

  validate_re($exactversion, '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$', 'please, provide the --fucking-- EXACT version, thanks')

  #$exactversion='12.1.0.1.0'

  if $exactversion =~ /^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+\.[0-9]+$/
  {
    #$version='12.1.0',
    $version=$1
  }

  if $exactversion =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.[0-9]+\.[0-9]+$/
  {
    #$version='12_1_0',
    $version_with_underscore="${1}_${2}_${3}"
  }

  if $exactversion =~ /^([0-9]+)\.[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/
  {
    #$majorversion='12',
    $majorversion=$1
  }

  if($localfile==undef) and ($package==undef)
  {
    fail('localfile (install file already in the local system) and package (remote file) are both undefined')
  }

  if($localfile!=undef) and ($package!=undef)
  {
    fail("Incompatible options: localfile(${localfile}) and package($package)")
  }

  package { $dependencies:
    ensure => 'installed',
  }

  Exec {
    path => '/usr/sbin:/usr/bin:/sbin:/bin',
  }

  if($createusers)
  {
    group { $oraclegroup:
      ensure => present,
    }

    group { $oracleinstallgroup:
      ensure => present,
    }

    user { $oracleuser:
      managehome => true,
      gid        => $oraclegroup,
      groups     => [ $oracleinstallgroup],
      shell      => '/bin/bash',
      home       => '/home/oracle',
      require    => Group[$oraclegroup],
    }
  }

  exec { "mkdir p ${oraclehome}":
    command => "mkdir -p ${oraclehome}",
    creates => $oraclehome,
  }

  exec { "mkdir p ${oraclebase}":
    command => "mkdir -p ${oraclebase}",
    creates => $oraclebase,
  }

  exec { "mkdir p ${orainventory}":
    command => "mkdir -p ${orainventory}",
    creates => $orainventory,
  }

  exec { "mkdir p ${srcdir}":
    command => "mkdir -p ${srcdir}",
    creates => $srcdir,
  }

  file { $oraclehome:
    ensure  => 'directory',
    owner   => $oracleuser,
    group   => $oraclegroup,
    mode    => '0755',
    require => Exec["mkdir p ${oraclehome}"],
  }

  file { $oraclebase:
    ensure  => 'directory',
    owner   => $oracleuser,
    group   => $oraclegroup,
    mode    => '0755',
    require => Exec["mkdir p ${oraclebase}"],
  }

  file { $orainventory:
    ensure  => 'directory',
    owner   => $oracleuser,
    group   => $oraclegroup,
    mode    => '0770',
    require => Exec["mkdir p ${orainventory}"],
  }

  file { $srcdir:
    ensure  => 'directory',
    owner   => $oracleuser,
    group   => $oraclegroup,
    mode    => '0750',
    require => Exec["mkdir p ${srcdir}"],
  }

  file { "${oraclehome}/responsefile.rsp":
    ensure  => 'present',
    owner   => $oracleuser,
    group   => $oraclegroup,
    mode    => '0644',
    content => template("${module_name}/responsefile${majorversion}.erb"),
    require => [ File[$oraclehome], User[$oracleuser] ],
  }

  if($localfile!=undef)
  {
    file { "${srcdir}/oracleclient-${version}.zip":
      ensure  => 'link',
      target  => $localfile,
      require => File[$srcdir],
    }
  }
  else
  {
    if $package =~ /^http/
    {
      exec { 'which wget eyp-oracleclient':
        command => 'which wget',
        unless  => 'which wget',
        require => Exec["mkdir p ${srcdir}"],
      }

      exec { 'wget oracleclient package':
        command => "wget ${package} -O ${srcdir}/oracleclient-${version}.zip",
        creates => "${srcdir}/oracleclient-${version}.zip",
        before  => Exec["unzip ${srcdir}/oracleclient-${version}.zip"],
        require => Exec['which wget eyp-oracleclient'],
      }
    }
    else
    {
      file { "${srcdir}/oracleclient-${version}.zip":
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        source  => $package,
        require => File[$srcdir],
        before  => Exec["unzip ${srcdir}/oracleclient-${version}.zip"],
      }
    }
  }


  exec { "unzip ${srcdir}/oracleclient-${version}.zip":
    command => "unzip ${srcdir}/oracleclient-${version}.zip" ,
    cwd     => $srcdir,
    require => Package[$dependencies],
    notify  => Exec["runinstaller client ${version}"],
    creates => "${srcdir}/client/runInstaller",
  }

  # Selecting Installer command upon oracle major version
  case $majorversion
  {
    '12':
    {
      $installer_command = "su - ${oracleuser} -c '${srcdir}/client/runInstaller -showProgress -waitforcompletion -silent -noconfig -debug -force -responseFile ${oraclehome}/responsefile.rsp' > ${oraclehome}/.runinstaller.log 2>&1"
    }
    '11':
    {
      $installer_command = "su - ${oracleuser} -c '${srcdir}/client/runInstaller -waitforcompletion -silent -noconfig -debug -force -responseFile ${oraclehome}/responsefile.rsp' > ${oraclehome}/.runinstaller.log 2>&1 ; /bin/egrep -i 'Successfully Setup Software' ${oraclehome}/.runinstaller.log"
    }
    default: { fail("Unsupported installer for Oracle ${majorversion}!")  }
  }

  exec { "runinstaller client ${version}":
    command     => $installer_command,
    timeout     => 0,
    require     => [ Exec["unzip ${srcdir}/oracleclient-${version}.zip"],
                  File[ [ $oraclehome, $oraclebase, $orainventory, $srcdir, "${oraclehome}/responsefile.rsp" ] ]
                  ],
    refreshonly => true,
    notify      => Exec["runinstaller client ${version} rootsh"],
  }

  exec { "runinstaller client ${version} rootsh":
    command     => "${oraclehome}/root.sh > ${oraclehome}/.rootsh.log 2>&1",
    timeout     => 0,
    require     => Exec["runinstaller client ${version}"],
    refreshonly => true,
  }

  concat {"${oracleclient::oraclehome}/network/admin/tnsnames.ora":
    ensure  => 'present',
    owner   => $oracleuser,
    group   => $oraclegroup,
    mode    => '0644',
    require => Exec[ [ "runinstaller client ${version}", "runinstaller client ${version} rootsh" ] ],
  }

  if($addtopath)
  {
    file { '/etc/profile.d/zz_puppetmanaget-oracle.sh':
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "export ORACLE_HOME=${oraclehome}\nexport PATH=\$PATH:${oraclehome}/bin\n",
      require => Exec["runinstaller client ${version} rootsh"],
    }
  }

  #/u01/app/product/11/client/lib
  ldconfig::diradd { "${oraclehome}/lib":
    type => 'oracleclient',
  }

  #/u01/app/oracle/client/11.2.0/
  ldconfig::diradd { "${oraclebase}/oracle/client/${version}":
    type => 'oracleclient',
  }


}
