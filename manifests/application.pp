
# == Type wsgi::application
# This type is used to manage the installation.
#
define wsgi::application (
  $ensure              = 'present',
  $owner               = undef,
  $group               = undef,
  $wsgi_entry          = $wsgi::params::wsgi_entry,
  $revision            = $wsgi::params::git_revision,
  $manage              = true,
  $logrotation         = false,
  $directory           = "${wsgi::params::app_dir}/${name}",
  $service             = "lr-${name}",
  $logrotate_freq      = 'weekly',
  $logrotate_rotate    = 4,
  $logging             = true,
  $centralised_logging = true,
  $workers             = $wsgi::params::workers,
  $threads      = $wsgi::params::threads,
  $bind         = undef,
  $vars         = undef,
  $deploy_vars  = undef,
  $source       = undef,
  $jar_name     = undef,
  $app_type     = 'wsgi',
  $vs_server    = undef,
  $environment  = undef,
  $vs_app_host  = undef,
  $vs_app_token = undef,
  $python_exe   = 'run.py',
  $command      = undef,
  $extra_args   = undef,
  $no_service   = false,
  $log_fields   = [],
  $healthcheck  = false,
  $repo_type    = 'git',
  $rpm_repo     = "${name}-repo",
  $rpm_package  = undef,

) {

  include stdlib

  # Static variables
  ##############################################################################

  # Put this in to compensate for some apps having different names to their source repo

  if $rpm_package == undef {
    $app_directory    = $directory
    $app_service      = $service
    $rpm_package_name = $name
  }  else {
    $app_directory = "${wsgi::params::app_dir}/${rpm_package}"
    $app_service   = "lr-${rpm_package}"

    if $rpm_package != $name {

      $rpm_package_name = $rpm_package

      file { $directory:
        ensure => absent,
        purge  => true,
        force  => true,
      }

      service { $service:
        ensure     => stopped,
        enable     => false,
        hasrestart => false,
        hasstatus  => false,
      }
    } else {
      $rpm_package_name = $name
    }
  }

  $venv_dir        = "${app_directory}/virtualenv"
  $code_dir        = "${app_directory}/source"
  $logs_dir        = "${app_directory}/logs"
  $pid_file        = "${app_directory}/${app_service}.pid"
  $cfg_file        = "${app_directory}/settings.conf"
  $dep_file        = "${app_directory}/deploy.conf"
  $start_sh        = "${app_directory}/startup.sh"
  $sysd_link       = "${app_directory}/${app_service}.service"
  $sysd_file       = "${wsgi::params::systemd}/${app_service}.service"
  $logrotate_file  = "${wsgi::params::logrotate}/${app_service}.conf"
  $commit_file     = "${app_directory}/COMMIT"
  $version_file    = "${app_directory}/VERSION"
  $access_log      = "${logs_dir}/access.log"
  $error_log       = "${logs_dir}/error.log"
  $application_log = "${logs_dir}/application.log"
  $log_level       = 'info'

  # If a user/group is not specified we should assume the user should have it's
  # own account for which we'll use the same name as the service itself.
  if $owner { $app_user  = $owner } else { $app_user  = $app_service }
  if $group { $app_group = $group } else { $app_group = $app_service }

  if $vs_server != undef and $environment != undef and $vs_app_host != undef {

    # Connect to version store to get repoistory, app version and variables
    $vs_json = getvars("${vs_app_host}/api/${environment}/${name}", $vs_app_token)

    $git_revision = $vs_json['version']
    $app_vars     = $vs_json['variables']
    $dep_vars     = $vs_json['variables_deployment']
    $repo_address = $vs_json['repository']
    $local_config = False
  } else {
    $git_revision = $revision
    $app_vars     = $vars
    $dep_vars     = $deploy_vars
    $repo_address = $source
    $local_config = True
  }

  # check if the application needs to run as a service
  if ! ($app_type in [ 'wsgi', 'jar', 'python' ]) or ! ($no_service == false) {
    $run_as_service = False
    $service_notify = undef
  } else {
    $run_as_service = True
    $service_notify = Service[$app_service]
  }

  # Install and configure application environment
  ##############################################################################
  if $ensure == 'present' {

    # Input validation
    ############################################################################
    if $repo_type == 'git' {
      if $repo_address == undef {
        fail( 'Source/repo_address parameter must be provided')
      }
    }
    # User account management
    ############################################################################

    if $app_user != $owner {
      user { $app_user :
        ensure  => present,
        system  => true,
        home    => $app_directory,
        comment => "LR service account for ${name}"
      }
    }
    if $app_group != $group {
      group { $app_group :
        ensure => present,
        system => true
      }
    }

    # Directory structure
    ############################################################################
    file { $app_directory:
      ensure  => directory,
      owner   => $app_user,
      group   => $app_group,
      mode    => '0775',
      require => Class[wsgi]
    }

    file { [$venv_dir, $code_dir]:
      ensure  => directory,
      owner   => $app_user,
      group   => $app_group,
      mode    => '0775',
      require => File[$app_directory]
    }

    file { $logs_dir:
      ensure  => directory,
      owner   => $app_user,
      group   => $app_group,
      mode    => '0775',
      seltype => 'var_log_t',
      require => File[$app_directory]
    }

    file { [$access_log, $error_log, $application_log]:
      ensure  => file,
      owner   => $app_user,
      group   => $app_group,
      mode    => '0644',
      seltype => 'var_log_t',
      require => File[$app_directory]
    }

    # Source code
    ############################################################################
    if $repo_type == 'git' {
      vcsrepo { $code_dir:
        ensure     => latest,
        provider   => 'git',
        source     => $repo_address,
        revision   => $git_revision,
        submodules => true,
        require    => File[$app_directory],
        notify     => [Exec[$commit_file], Exec[$version_file]]
      }

      exec { $commit_file:
        command     => "git rev-parse --verify HEAD > ${commit_file}",
        user        => $app_user,
        group       => $app_group,
        cwd         => $code_dir,
        refreshonly => true,
        path        => '/usr/local/bin:/usr/bin:/bin',
        require     => Vcsrepo[$code_dir],
        notify      => $service_notify
      }

      if $git_revision == undef {
        exec { $version_file:
          command     => "echo 'latest' > ${version_file}",
          user        => $app_user,
          group       => $app_group,
          cwd         => $code_dir,
          refreshonly => true,
          path        => '/usr/local/bin:/usr/bin:/bin',
          require     => Vcsrepo[$code_dir]
        }
      } else {
        exec { $version_file:
          command     => "echo ${revision} > ${version_file}",
          user        => $app_user,
          group       => $app_group,
          cwd         => $code_dir,
          refreshonly => true,
          path        => '/usr/local/bin:/usr/bin:/bin',
          require     => Vcsrepo[$code_dir]
        }
      }
    } elsif $repo_type == 'yum' {

      # Install application package
      package { $rpm_package_name :
        ensure => latest,
        notify => $service_notify
      }
    }

    # Application Type Custom Code
    ############################################################################
    if ($app_type == 'wsgi') {

      wsgi::types::wsgi { $name:
        code_dir  => $code_dir,
        venv_dir  => $venv_dir,
        owner     => $app_user,
        group     => $app_group,
        service   => $app_service,
        cfg_file  => $cfg_file,
        dep_file  => $dep_file,
        start_sh  => $start_sh,
        bind      => $bind,
        repo_type => $repo_type
      }

    } elsif ($app_type == 'jar') {

      wsgi::types::jar { $name:
        code_dir => $code_dir,
        owner    => $app_user,
        group    => $app_group,
        service  => $app_service,
        cfg_file => $cfg_file,
        dep_file => $dep_file,
        start_sh => $start_sh,
        jar_name => $jar_name,
        bind     => $bind
      }

    } elsif ($app_type == 'python') {

      wsgi::types::python { $name:
        code_dir  => $code_dir,
        venv_dir  => $venv_dir,
        owner     => $app_user,
        group     => $app_group,
        service   => $app_service,
        cfg_file  => $cfg_file,
        dep_file  => $dep_file,
        start_sh  => $start_sh,
        bind      => $bind,
        command   => $command,
        repo_type => $repo_type
      }

    } elsif ($app_type == 'batch') {

      # Nothing extra needs to be done

    } else {
      fail( 'Not a valid app type')
    }

    # Logging configuration
    ############################################################################
    $filebeat_dirs = ['/etc/filebeat', '/etc/filebeat/filebeat.d']
    $filebeat_conf = "/etc/filebeat/filebeat.d/${app_service}.yml"

    if $centralised_logging {
      # Because Puppet doesn't manage entire directory trees (why?), we need to
      # create but not manage the parent directories.
      ensure_resource('file', $filebeat_dirs, { ensure => directory })

      file { $filebeat_conf :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('wsgi/filebeat.erb')
      }
    } else {
      file { $filebeat_conf : ensure => absent }
    }
    if $logrotation {
      #
      #  If not set correctly
      if ! ($logrotate_freq in [ 'hourly', 'daily', 'weekly', 'monthly', 'yearly' ]) {
        fail("Invalid value ${logrotate_freq} for \$logrotate_freq.")
      }

      file { $logrotate_file :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('wsgi/logrotate.erb')
      }
    } else {
      file { $logrotate_file : ensure => absent }
    }

    # Configuration
    ############################################################################
    file { $cfg_file:
      ensure  => file,
      owner   => $app_user,
      group   => $app_group,
      mode    => '0640',
      content => template('wsgi/environment.erb'),
      require => File[$app_directory],
      notify  => $service_notify
    }

    file { $dep_file:
      ensure  => file,
      owner   => $app_user,
      group   => $app_group,
      mode    => '0640',
      content => template('wsgi/deploy.erb'),
      require => File[$app_directory],
      notify  => $service_notify
    }

    # Only create the service if required
    if ($run_as_service == True) {
      file { $sysd_file:
        ensure  => file,
        owner   => $app_user,
        group   => $app_group,
        mode    => '0664',
        content => template('wsgi/service.erb'),
        require => [File[$start_sh], File[$logs_dir]],
        notify  => Service[$app_service]
      }

      if $repo_type == 'git' {
        $subscribe = "Vcsrepo[${code_dir}]"
      } elsif $repo_type == 'yum' {
        $subscribe = "Package[${rpm_package_name}]"
      }
      file { $sysd_link:
        ensure    => link,
        owner     => $app_user,
        target    => $sysd_file,
        group     => $app_group,
        require   => File[$sysd_file],
        subscribe => $subscribe
      }

      service { $app_service:
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => File[$sysd_file]
      }
    } else {
      file { $sysd_file:
        ensure => absent,
      }
      file { $sysd_link:
        ensure => absent,
      }
      service { $app_service:
        ensure => stopped,
        enable => false
      }
    }


    exec { "file-ownership-${name}" :
      command => "/usr/bin/chown -R ${app_user}:${app_group} ${app_directory}",
      onlyif  => "/usr/bin/test $(/usr/bin/find ${app_directory} ! -user ${app_user} | wc -l) != '0'",
      require => $subscribe
    }

    exec { "systemd-reload-${name}" :
      command     => '/usr/bin/systemctl daemon-reload',
      refreshonly => true,
      subscribe   => File[$sysd_file],
      notify      => Service[$app_service]
    }

  # Remove application & configuration
  ##############################################################################
  } elsif $ensure == 'absent' {

    # If we have created an account specifically for this application, we'll
    # need to clean that account up at the end of our work.
    if $app_user != $owner  { user { $app_user : ensure => absent }}
    if $app_group != $group { group { $app_group : ensure => absent }}

    file { $app_directory:
      ensure  => absent,
      force   => true,
      purge   => true,
      recurse => true,
    }

    service { $app_service:
      ensure => stopped,
      enable => false
    }

    file { $sysd_file :      ensure => absent }
    file { $logrotate_file : ensure => absent }

  # Fail if we receive an unusual ensure value
  ##############################################################################
  } else {
    fail( "Illegal ensure value: ${ensure}. Expected 'present' or 'absent'")
  }

}
