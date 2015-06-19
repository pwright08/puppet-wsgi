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
class { 'wsgi': } ->
wsgi::application { 'cases-frontend':
  bind       => '5000',
  source     => 'https://github.com/LandRegistry/cases-frontend.git',
  wsgi_entry => 'application:app',
  vars       => {
    db_url => 'http://ghj',
  }
} ->
wsgi::application { 'cases-api':
  bind       => '5001',
  source     => 'https://github.com/LandRegistry/cases-api.git',
  wsgi_entry => 'application:app',
} ->
wsgi::application { 'test-api':
  ensure => absent
} ->
wsgi::application { 'digital-register-feeder':
  source     => 'git@github.com:LandRegistry/digital-register-feeder.git',
  app_type   => 'python',
  vars       => {
    'SETTINGS'                     => 'test',
    'REGISTER_FILES_PATH'          => 'data',
    'POSTGRES_USER'                => 'postgres',
    'POSTGRES_PASSWORD'            => 'password',
    'POSTGRES_HOST'                => '127.0.0.1',
    'POSTGRES_PORT'                => '5432',
    'POSTGRES_DB'                  => 'register_data',
    'DIGITAL_REGISTER_URL'         => 'http://landregistry.local:8003',
    'ELASTICSEARCH_HOST'           => 'localhost',
    'ELASTICSEARCH_PORT'           => '9200',
    'INCOMING_QUEUE'               => 'publish_queue',
    'INCOMING_QUEUE_HOSTNAME'      => 'localhost',
    'LOGGING_CONFIG_FILE_PATH'     => 'logging_config.json',
    'FAULT_LOG_FILE_PATH'          => '/var/log/digital-register-feeder-fault.log',
    'SHOW_PRIVATE_PROPRIETORS'     => 'true',
    'LOG_SCHEMA_VALIDATION_ERRORS' => 'false',
  }
}
