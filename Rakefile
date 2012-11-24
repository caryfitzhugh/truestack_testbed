require 'json'
require 'net/http'
SERVER_PORT=3007
COLLECTOR_PORT=10001
MONGOLAB_DB_NAME='truestack_testbed'
MONGOLAB_URI_DEVELOPMENT="http://localhost:27017/#{MONGOLAB_DB_NAME}"
API_TOKEN='123456789abcdefghijklmnop'

require 'rubygems'
require 'pry'
require 'pry-nav'


desc "Run the tests for every test system in this repository"
task :run do
  `rm log/*`

  Rake::Task['mongo:drop'].execute
  Rake::Task['server:start'].execute
  Rake::Task['collector:start'].execute

  # Create the user for admin access
  `./scripts/create_admin_user #{API_TOKEN} #{MONGOLAB_URI_DEVELOPMENT}`

  begin
    # We go into each testcase directory
    # Open each 'testcase' directory.
    system_under_test_port = 4000

    Dir["systems_under_test/*"].each do |system_under_test|
      puts "Running system: #{File.dirname(system_under_test)}"
      puts "API Token created"

      puts "Create a user application"
      ts_uri = URI("http://localhost:#{SERVER_PORT}/api/apps")

      truestack_uri = nil
      truestack_app_id = nil
      Net::HTTP.start(ts_uri.host, ts_uri.port) do |http|
        req = Net::HTTP::Post.new ts_uri.path
        req.set_form_data("name" => "User App #{system_under_test}")
        req.add_field("Truestack-Access-Key", API_TOKEN)
        response = http.request req
        message = JSON.parse(response.body)
        truestack_uri = message['url']
        truestack_app_id = message['id']
      end
      puts "obtained TS url: #{truestack_uri}"

      puts "\n\n# System under test #{system_under_test}"
      # Start system under test with new user app name
      run_process("scripts/start_system_under_test #{system_under_test_port} #{system_under_test} #{truestack_uri}") do |pid|
        begin
          wait_for_open_port(system_under_test_port, pid)
          puts "? startup event "
            ts_uri = URI("http://localhost:#{SERVER_PORT}/api/apps/#{truestack_app_id}/deployments")
            Net::HTTP.start(ts_uri.host, ts_uri.port) do |http|
              req = Net::HTTP::Get.new ts_uri.path
              req.add_field("Truestack-Access-Key", API_TOKEN)
              response = http.request req
              message = JSON.parse(response.body)
              if (message.length < 1)
                raise "- FAIL: Did not have the deployment action"
              end
              puts "+ PASS"
            end

          puts "# /exception"
          puts "? exception event in the TS server"
          puts "# /request"

          puts "? a pair of reqeusts in TS server"
        rescue Exception => e
          puts "Failed: #{e}"
        end
      end
    end
  ensure
    Rake::Task['collector:stop'].execute
    Rake::Task['server:stop'].execute
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
    collector_pid = Process.spawn({'MONGOLAB_URI_DEVELOPMENT' => MONGOLAB_URI_DEVELOPMENT},
                                   "./scripts/start_collector http://127.0.0.1:#{COLLECTOR_PORT}",
                                   [:err, :out] => [File.join('log','collector.log').to_s, 'w'])
    tries = 0
    puts "Starting collector on port #{COLLECTOR_PORT}."
    wait_for_open_port(COLLECTOR_PORT, collector_pid)

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
    server_pid = Process.spawn({'MONGOLAB_URI_DEVELOPMENT' => MONGOLAB_URI_DEVELOPMENT},
                               "./scripts/start_server #{SERVER_PORT}",
                               [:err, :out] => [File.join('log','server.log').to_s, 'w'])
    tries = 0
    puts "Starting server on port #{SERVER_PORT}."
    wait_for_open_port(SERVER_PORT, server_pid)

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


def run_process(string)
  system_under_test_pid = Process.spawn(string, [:err, :out] => [File.join('log',"#{string.gsub(/\W/,'_')}.log").to_s, 'w'])
  yield
  # Stop the system under test
  Process.kill("SIGKILL", system_under_test_pid)
end

def wait_for_open_port(port, pid = nil)
  while !is_port_open?('127.0.0.1', port)
    sleep 1
    if (pid)
    print "."
      begin
        Process.getpgid( pid )
      rescue Errno::ESRCH
        raise "Server for port #{port} failed on startup"
      end
     end
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
