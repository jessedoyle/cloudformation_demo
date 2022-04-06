APP_DIR     = File.expand_path("../..", __FILE__).freeze
APP_NAME    = ENV.fetch('APP_NAME') { 'cloudformation_demo' }.freeze
ENVIRONMENT = ENV.fetch('RAILS_ENV') { 'development' }.freeze
MAX_THREADS = ENV.fetch('RAILS_MAX_THREADS') { 5 }.freeze
MIN_THREADS = ENV.fetch('RAILS_MIN_THREADS') { MAX_THREADS }.freeze
STATEFILE   = ENV.fetch('STATEFILE') { File.join(APP_DIR, 'tmp', 'pids', 'puma.state') }.freeze
PIDFILE     = ENV.fetch('PIDFILE') { File.join(APP_DIR, 'tmp', 'pids', 'puma.pid') }.freeze
BIND        = ENV.fetch('BIND') { 'tcp://0.0.0.0:3000' }.freeze
WORKERS     = ENV['WORKERS'].freeze
STDOUT_PATH = ENV['STDOUT_PATH'].freeze
STDERR_PATH = ENV['STDERR_PATH'].freeze

threads(MIN_THREADS, MAX_THREADS)
pidfile(PIDFILE)
environment(ENVIRONMENT)
bind(BIND)
tag(APP_NAME)
state_path(STATEFILE)
if STDOUT_PATH
  stderr_path = STDERR_PATH || STDOUT_PATH
  stdout_redirect(STDOUT_PATH, stderr_path, true)
end

if WORKERS
  prune_bundler
  workers(WORKERS)
  worker_timeout(60)
  worker_boot_timeout(60)
end

plugin :tmp_restart
