class oracleclient::params {

  case $::osfamily
  {
    'redhat':
        {
      case $::operatingsystemrelease
      {
        /^[67].*$/:
        {
          $dependencies= [ 'unzip' , 'gawk' ]
        }
        default: { fail("Unsupported RHEL/CentOS version! - $::operatingsystemrelease")  }
      }

    }
    'Debian':
    {
      fail("Unsupported")
    }
    default: { fail("Unsupported OS!")  }
  }
}
