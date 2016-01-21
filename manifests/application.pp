
# == Type wsgi::application
# This type is used to manage the installation.
#
define wsgi::application (
  $ensure       = 'present',
  $owner        = $wsgi::params::user,
  $group        = $wsgi::params::group,
  $wsgi_entry   = $wsgi::params::wsgi_entry,
  $revision     = $wsgi::params::git_revision,
  $directory    = "${wsgi::params::app_dir}/${name}",
  $service      = "lr-${name}",
  $manage       = true,
  $bind         = undef,
  $vars         = undef,
  $source       = undef,
  $jar_name     = undef,
  $app_type     = undef,
  $vs_server    = undef,
  $environment  = undef,
  $vs_app_host  = undef,
  $vs_app_token = undef
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

  if $vs_server != undef and $environment != undef and $vs_app_host != undef {

    # Connect to version store to get repoistory, app version and variables
    $vs_json = getvars("${vs_app_host}/api/${environment}/${name}", $vs_app_token)

    $git_revision = $vs_json['version']
    $app_vars = $vs_json['variables']
    $repo_address = $vs_json['repository']
    $local_config = False
  } else {
    $git_revision = $revision
    $app_vars = $vars
    $repo_address = $source
    $local_config = True
  }

  # Install and configure application environment
  ##############################################################################
  if $ensure == 'present' {


    # Input validation
    ############################################################################
    if $repo_address == undef {
      fail( 'Source/repo_address parameter must be provided')
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
      ensure     => latest,
      provider   => 'git',
      source     => $repo_address,
      revision   => $git_revision,
      submodules => true,
      require    => File[$directory],
      notify     => [Exec[$commit_file], Exec[$version_file]]
    }

    exec { $commit_file:
      command     => "git rev-parse --verify HEAD > ${commit_file}",
      user        => $owner,
      group       => $group,
      cwd         => $code_dir,
      refreshonly => true,
      path        => '/usr/local/bin:/usr/bin:/bin',
      require     => Vcsrepo[$code_dir],
      notify      => Service[$service]
    }

    if $git_revision == undef {
      exec { $version_file:
        command     => "echo 'latest' > ${version_file}",
        user        => $owner,
        group       => $group,
        cwd         => $code_dir,
        refreshonly => true,
        path        => '/usr/local/bin:/usr/bin:/bin',
        require     => Vcsrepo[$code_dir]
      }
    } else {
      exec { $version_file:
        command     => "echo ${revision} > ${version_file}",
        user        => $owner,
        group       => $group,
        cwd         => $code_dir,
        refreshonly => true,
        path        => '/usr/local/bin:/usr/bin:/bin',
        require     => Vcsrepo[$code_dir]
      }
    }

    # Application Type Custom Code
    ############################################################################
    if ($app_type == 'wsgi') {

      wsgi::types::wsgi { $name:
        code_dir => $code_dir,
        venv_dir => $venv_dir,
        owner    => $owner,
        group    => $group,
        service  => $service,
        cfg_file => $cfg_file,
        start_sh => $start_sh,
        bind     => $bind
      }

    } elsif ($app_type == 'jar') {

      wsgi::types::jar { $name:
        code_dir => $code_dir,
        owner    => $owner,
        group    => $group,
        service  => $service,
        cfg_file => $cfg_file,
        start_sh => $start_sh,
        jar_name => $jar_name,
        bind     => $bind
      }

    } else {
      fail( 'Not a valid app type')
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

    file { $sysd_file:
      ensure  => file,
      owner   => $owner,
      group   => $group,
      mode    => '0664',
      content => template('wsgi/service.erb'),
      require => [File[$start_sh], File[$logs_dir]],
      notify  => Service[$service]
    }

    file { $sysd_link:
      ensure    => link,
      target    => $sysd_file,
      require   => File[$sysd_file],
      subscribe => Vcsrepo[$code_dir]
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
