require 'net/http'
SERVER_PORT=3007
COLLECTOR_PORT=10001
MONGOLAB_DB_NAME='truestack_testbed'
MONGOLAB_URI="http://localhost:27017/#{MONGOLAB_DB_NAME}"
API_TOKEN='123456789abcdefghijklmnop'

desc "Run the tests for every test system in this repository"
task :run do
  # We start the TS target server (submodule in server)
  Rake::Task['server:start'].execute

  begin
    # We go into each testcase directory
    # Open each 'testcase' directory.
    # Dump the DB
    Rake::Task['mongo:drop'].execute

    # Stop / start each ts server

    # Create the user
    `./create_admin_user #{API_TOKEN}`
  ensure
    Rake::Task['server:start'].execute
  end
end

namespace :mongo do
  desc 'Clear out the mongo test db'
  task :drop do
    puts "Dropping #{MONGOLAB_DB_NAME}"
    `mongo #{MONGOLAB_DB_NAME} --eval "db.dropDatabase()"`
  end
end

namespace :collector do
  desc "Start a collector instance"
  task :start do
    collector_pid = Process.spawn({'MONGOLAB_URI' => MONGOLAB_URI},
                                   "./start_collector http://127.0.0.1:#{COLLECTOR_PORT}",
                                   [:err, :out] => [File.join('log','collector.log').to_s, 'w'])
    tries = 0
    puts "Starting server on port #{SERVER_PORT}."

    while !is_port_open?('127.0.0.1', 10000) && tries < 20
      tries += 1
      sleep 1
      print "."
    end
    puts "\nStarted"

    File.open("pids/collector.pid", 'w') do |f|
      f.write(collector_pid.to_s)
    end
  end

  task :stop do
    pid = File.read("pids/collector.pid").to_i
    puts "Stopping collector at pid #{pid}"
    Process.kill("SIGKILL", pid)
  end
end

namespace :server do
  desc "Start the latest truestack server instance"
  task :start do
    server_pid = Process.spawn({'MONGOLAB_URI' => MONGOLAB_URI},
                               "./start_server #{SERVER_PORT}",
                               [:err, :out] => [File.join('log','server.log').to_s, 'w'])
    tries = 0
    puts "Starting server on port #{SERVER_PORT}."
    while !is_port_open?('127.0.0.1', SERVER_PORT)
      tries += 1
      sleep 1
      print "."
    end

    puts "\nStarted."

    File.open("pids/server.pid", 'w') do |f|
      f.write(server_pid.to_s)
    end
  end

  desc "Start the running truestack server instance"
  task :stop do
    begin
      pid = File.read("pids/server.pid").to_i
      if (pid)
        puts "Stopping server at pid #{pid}"
        Process.kill("SIGKILL", pid)
      end
    rescue Exception
    end
    `rm -f pids/server.pid`
  end
end

def is_port_open?(ip, port)
  begin
    Timeout::timeout(1) do
      begin
        s = TCPSocket.new(ip, port)
        s.close
        return true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return false
      end
    end
  rescue Timeout::Error
  end
  return false
end
