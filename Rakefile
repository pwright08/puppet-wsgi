require 'rake'
require 'puppet-syntax/tasks/puppet-syntax'
require 'puppet-lint/tasks/puppet-lint'
require 'colorize'

# Ignore these directories in tests
exclude_paths = [ 'modules/**/*.pp', 'tests/*.pp' ]

# Puppet lint task (:lint)
# You can troubleshoot errors and warnings @ http://puppet-lint.com/checks/
desc "Run lint tasks against manifests"
Rake::Task[:lint].clear # https://github.com/rodjek/puppet-lint/issues/331
PuppetLint::RakeTask.new :lint do |config|
  config.fail_on_warnings = true
  config.ignore_paths = exclude_paths
  config.disable_checks = ['80chars', 'autoloader_layout', 'class_inherits_from_params_class', 'documentation']
  config.log_format = "%{path}:%{linenumber}:%{check}:%{KIND}:%{message}"
end

# Puppet syntax task (:syntax)
PuppetSyntax.exclude_paths = exclude_paths

# Hiera syntax task (:hiera)
desc "Test Hiera files can be parsed correctly"
task :hiera do
  require 'yaml'
  failure = false

  d = Dir["hiera/**/*.yaml", "hiera/**/*.yml"]
  d.each do |file|
    begin
      YAML.load_file(file)
    rescue Exception
      puts "Hiera syntax - Failed to read #{file}: #{$!}".red
      failure = true
    end
  end
  if failure == true
    exit 1
  end
end

# Shell syntax task (:shell)
desc "Test shell script syntax"
task :shell do
  require 'open4'
  failure = false

  d = Dir["**/*.sh"]
  d.each do |file|
    pid, stdin, stdout, stderr = Open4.popen4("bash -n #{file}")
    ignored, status = Process::waitpid2 pid
    unless status.to_i == 0 # Check if script exits with non-zero status
      begin
        result = stderr.gets.chomp.sub(" syntax error:",'')
        puts "Shell syntax - #{result}".red
      rescue
        puts "Shell syntax - Error reading output of #{file}".red
      end
      failure = true
    end
  end
  if failure == true
    exit 1
  end
end

# Puppet unit test task (:unit)
desc "Puppet unit tests - requires sudo privledges"
task :unit do
  require 'open4'
  modulepath = "./site:./modules"
  puppetcmd = "sudo puppet apply --noop --detailed-exitcodes --modulepath=#{modulepath}"
  failure = false
  failures = []

  def cleanpuppet input
    cleaned = input.to_s.gsub(/Could .*: | on node .*|\x1b\[[0-9;]*m/,"").chomp
    return "Unit test - " + cleaned
  end

  d = Dir["site/*/tests/**/*.pp"]
  d.each do |file|
    puts "Unit test - Running #{file} in noop mode"
    pid, stdin, stdout, stderr = Open4.popen4("#{puppetcmd} #{file} >/dev/null")
    ignored, status = Process::waitpid2 pid
    unless status.to_i == 0 # Check if test run exists with non-zero status
      while not stderr.eof?
        puts cleanpuppet(stderr.gets).red
      end
      failure = true
      failures.push(file)
      next
    end
    while not stderr.eof?
      puts cleanpuppet(stderr.gets).yellow
    end
  end
  if failure == true
    f = failures.join(", ")
    puts "Unit test - Tests run against the following test manifests failed: #{f}".red
    exit 1
  end
end

desc "Basic validation testing"
task :validation => [:syntax, :lint, :hiera, :shell]

desc "Full test suite - requires sudo privledges"
task :test => [:validation, :unit]

task :default => :test
