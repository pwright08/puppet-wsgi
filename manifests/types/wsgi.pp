
define wsgi::types::wsgi(
  $code_dir = undef,
  $venv_dir = undef,
  $owner    = undef,
  $group    = undef,
  $service  = undef,
  $cfg_file = undef,
  $dep_file = undef,
  $start_sh = undef,
  $bind     = undef,
  ){

    if $bind == undef {
      fail( 'Bind value must be set to an integer representing a network port')
    }

  if ($repo_type == 'git') {
    # Virtual environment
    ############################################################################
    file { "${name} requirements.txt":
      ensure  => file,
      path    => "${code_dir}/requirements.txt",
      owner   => $owner,
      group   => $group,
      require => [File[$code_dir], Vcsrepo[$code_dir]]
    }

    exec { "${name} virtualenv":
      command => "python3 -m venv ${venv_dir}",
      user    => $owner,
      group   => $group,
      creates => "${venv_dir}/bin/activate",
      path    => '/usr/bin:/bin:/sbin',
      unless  => "grep '^[\\t ]*VIRTUAL_ENV=[\\\\'\\\"]*${venv_dir}[\\\"\\\\'][\\t ]*$' ${venv_dir}/bin/activate",
      require => [File[$venv_dir], Class['wsgi::dependencies::python']],
      notify  => Exec["${name} dependencies"]
    }

    file { "${name} python":
      ensure  => link,
      path    => "${venv_dir}/bin/python3.4",
      target  => '/usr/bin/python3.4',
      owner   => $owner,
      group   => $group,
      require => Exec["${name} virtualenv"]
    }

    exec { "${name} dependencies":
      command     => "${venv_dir}/bin/pip install -r ${code_dir}/requirements.txt",
      user        => $owner,
      group       => $group,
      require     => [File["${name} python"], File["${name} requirements.txt"]],
      subscribe   => Vcsrepo[$code_dir],
      refreshonly => true
    }

    exec { "${name} gunicorn":
      command => "${venv_dir}/bin/pip install gunicorn",
      user    => $owner,
      group   => $group,
      creates => "${venv_dir}/bin/gunicorn",
      require => Exec["${name} dependencies"],
      before  => Service[$service],
    }
  }
    # Specific Configuration
    ############################################################################

    file { $start_sh:
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => '0775',
      content => template('wsgi/startup_wsgi.erb'),
      require => File[$cfg_file],
      notify  => Service[$service]
    }

}
