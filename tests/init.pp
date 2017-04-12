# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# http://docs.puppetlabs.com/guides/tests_smoke.html
#
include wsgi
wsgi::application { 'test-app' :
  bind        => '5000',
  wsgi_entry  => 'application.server:app',
  source      => 'https://github.com/mooreandrew/test-app.git',
  environment => 'Integration',
  app_type    => 'wsgi',
  vars        => {
    'TESTVALUE' => 'test',
    'SETTINGS'  => 'config.DevelopmentConfig'
  },
  deploy_vars => {
    'TESTVALUE' => 'deploy'
  }
} ->
wsgi::application { 'spark-app' :
  bind        => '5001',
  source      => 'https://github.com/mooreandrew/gradle-test-jar.git',
  environment => 'Integration',
  app_type    => 'jar',
  jar_name    => 'gradle_test-1.0.jar',
  logging     => true,
  vars        => {
    'TESTVALUE' => 'test',
  },
  centralised_logging => true,
  log_fields  => [
    'application_environment'
  ],
} ->
wsgi::application { 'test-python-app' :
  bind        => '5003',
  source      => 'https://github.com/mooreandrew/test-app.git',
  environment => 'Integration',
  app_type    => 'python',
  centralised_logging => true,
  vars        => {
    'TESTVALUE' => 'test',
  }
} ->
wsgi::application { 'scheduled_file' :
  source      => 'https://github.com/mooreandrew/gradle-test-jar.git',
  environment => 'Integration',
  app_type    => 'batch',
  logging     => true,
  centralised_logging => true,
  vars        => {
    'TESTVALUE' => 'test',
  }
} ->
wsgi::application { 'test_absent1' :
  ensure      => absent,
  app_type    => 'wsgi',
} ->
wsgi::application { 'test_absent2' :
  ensure      => absent,
  app_type    => 'batch',
}
