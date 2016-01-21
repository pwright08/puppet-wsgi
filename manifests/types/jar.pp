


define wsgi::types::jar(
  $code_dir = undef,
  $owner    = undef,
  $group    = undef,
  $service  = undef,
  $cfg_file = undef,
  $start_sh = undef,
  $jar_name = undef,
  $bind     = undef,
  ){

    if $jar_name == undef {
      fail( 'You must specify a jar file name')
    }

    # Specific Configuration
    ############################################################################

    file { $start_sh:
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => '0775',
      content => template('wsgi/startup_jar.erb'),
      require => File[$cfg_file],
      notify  => Service[$service]
    }

}
