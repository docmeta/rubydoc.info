app_dir = File.expand_path(File.dirname(__FILE__))
worker_processes 3
working_directory app_dir
#listen "#{app_dir}/tmp/sock/unicorn.sock"
listen 8080, :tcp_nopush => true
pid "#{app_dir}/tmp/pids/unicorn.pid"
stderr_path "#{app_dir}/log/unicorn.log"
stdout_path "#{app_dir}/log/unicorn.log"
preload_app true

before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = "#{app_dir}/tmp/pids/unicorn.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end
