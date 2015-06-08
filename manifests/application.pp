
# == Type wsgi::application
# This type is used to manage the installation.
#
define wsgi::application (

  $ensure     = 'present',
  $owner      = 'root',
  $group      = 'root',
  $wsgi_entry = $wsgi::params::wsgi_entry,
  $directory  = "${wsgi::params::app_dir}/${name}",
  $service    = "lr-${name}",
  $manage     = true,
  $bind       = undef,
  $vars       = undef,
  $source     = undef,
  $revision   = undef,

) {

  include stdlib

  # Static variables
  ##############################################################################
  $venv_dir     = "${directory}/virtualenv"
  $code_dir     = "${directory}/source"
  $logs_dir     = "${directory}/logs"
  $pid_file     = "${directory}/${service}.pid"
  $cfg_file     = "${directory}/settings.conf"
  $start_sh     = "${directory}/startup.sh"
  $sysd_link    = "${directory}/${service}.service"
  $sysd_file    = "${wsgi::params::systemd}/${service}.service"
  $commit_file  = "${directory}/COMMIT"
  $version_file = "${directory}/VERSION"
  $access_log   = "${logs_dir}/access.log"
  $error_log    = "${logs_dir}/error.log"
  $log_level    = 'info'


  # Install and configure application environment
  ##############################################################################
  if $ensure == 'present' {


    # Input validation
    ############################################################################
    if $bind == undef {
      fail( 'Bind value must be set to an integer representing a network port')
    }
    if $source == undef {
      fail( 'Source parameter must be provided')
    }


    # Directory structure
    ############################################################################
    file { $directory:
      ensure  => directory,
      owner   => $owner,
      group   => $group,
      mode    => '0775',
      require => Class[wsgi]
    }

    file { [$venv_dir, $logs_dir, $code_dir]:
      ensure  => directory,
      owner   => $owner,
      group   => $group,
      mode    => '0775',
      require => File[$directory]
    }

    file { [$access_log, $error_log]:
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => '0644',
      require => File[$directory]
    }


    # Source code
    ############################################################################
    vcsrepo { $code_dir:
      ensure   => present,
      provider => 'git',
      source   => $source,
      revision => $revision,
      require  => File[$directory],
      notify   => [Exec[$commit_file], Exec[$version_file]],
      before   => File["${name} requirements.txt"]
    }

    exec { $commit_file:
      command => "git rev-parse --verify HEAD > ${commit_file}",
      user    => $owner,
      group   => $group,
      cwd     => $code_dir,
      creates => $commit_file,
      path    => '/usr/local/bin:/usr/bin:/bin',
      require => Vcsrepo[$code_dir]
    }

    if $revision == undef {
      exec { $version_file:
        command => "echo 'latest' > ${version_file}",
        user    => $owner,
        group   => $group,
        cwd     => $code_dir,
        creates => $version_file,
        path    => '/usr/local/bin:/usr/bin:/bin',
        require => Vcsrepo[$code_dir]
      }
    } else {
      exec { $version_file:
        command => "echo ${revision} > ${version_file}",
        user    => $owner,
        group   => $group,
        cwd     => $code_dir,
        creates => $version_file,
        path    => '/usr/local/bin:/usr/bin:/bin',
        require => Vcsrepo[$code_dir]
      }
    }


    # Virtual environment
    ############################################################################
    file { "${name} requirements.txt":
      ensure  => file,
      path    => "${code_dir}/requirements.txt",
      owner   => $owner,
      group   => $group,
      require => File[$code_dir]
    }

    exec { "${name} virtualenv":
      command => "pyvenv3 ${venv_dir}",
      user    => $owner,
      group   => $group,
      creates => "${venv_dir}/bin/activate",
      path    => '/usr/local/bin:/usr/bin:/bin',
      unless  => "grep '^[\\t ]*VIRTUAL_ENV=[\\\\'\\\"]*${venv_dir}[\\\"\\\\'][\\t ]*$' ${venv_dir}/bin/activate",
      require => File[$venv_dir],
      notify  => Exec["${name} dependencies"]
    }

    exec { "${name} dependencies":
      command     => "${venv_dir}/bin/pip install -r ${code_dir}/requirements.txt",
      user        => $owner,
      group       => $group,
      require     => [Exec["${name} virtualenv"], File["${name} requirements.txt"]],
      refreshonly => true
    }

    exec { "${name} gunicorn":
      command => "${venv_dir}/bin/pip install gunicorn",
      user    => $owner,
      group   => $group,
      creates => "${venv_dir}/bin/gunicorn",
      require => Exec["${name} dependencies"]
    }


    # Configuration
    ############################################################################
    file { $cfg_file:
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => '0664',
      content => template('wsgi/environment.erb'),
      require => File[$directory],
      notify  => Service[$service]
    }

    file { $start_sh:
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => '0775',
      content => template('wsgi/startup.erb'),
      require => File[$cfg_file],
      notify  => Service[$service]
    }

    file { $sysd_file:
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => '0664',
      content => template('wsgi/service.erb'),
      require => [File[$start_sh], File[$logs_dir], Exec["${name} gunicorn"]],
      notify  => Service[$service]
    }

    file { $sysd_link:
      ensure  => link,
      target  => $sysd_file,
      require => File[$sysd_file]
    }

    service { $service:
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      require    => File[$sysd_file]
    }


  # Remove application & configuration
  ##############################################################################
  } elsif $ensure == 'absent' {

    file { $directory:
      ensure  => absent,
      force   => true,
      purge   => true,
      recurse => true,
    }

    service { $service:
      ensure => stopped,
      enable => false
    }

    file { $sysd_file:
      ensure => absent
    }


  # Fail if we receive an unusual ensure value
  ##############################################################################
  } else {
    fail( "Illegal ensure value: ${ensure}. Expected 'present' or 'absent'")
  }

}
