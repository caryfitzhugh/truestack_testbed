require 'net/http'
SERVER_PORT=3007
MONGODB_PORT=27018

namespace :test do
  desc "Run the tests for every test system in this repository"
  task :all do

  end

  namespace :mongodb do
    desc "Start your mongo process" do

    end

    desc "Stop the mongo process" do

    end
  end

  namespace :collector do
    desc "Start a collector instance"
    task :start do
      collector_pid = Process.spawn({'RAILS_ENV' => ENV['RAILS_ENV']},
                                     "cd server && source .rvmrc && bundle install && bundle exec rake workers:collector:start[#{@test_url}] --trace",
                                     [:err, :out] => [File.join('log','collector.log').to_s, 'w'])
      tries = 0
      while !is_port_open?('127.0.0.1', 10000) && tries < 20
        tries += 1
        sleep 1
      end
      File.open("pids/collector.pid", 'w') do |f|
        f.write(collector_pid.to_s)
      end
    end

    task :stop do
      pid = File.read("pids/collector.pid").to_i
      Process.kill("SIGKILL", pid)
    end
  end

  namespace :server do
    desc "Start the latest truestack server instance"
    task :start do
      server_pid = Process.spawn({'RAILS_ENV' => ENV['RAILS_ENV']},
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
      pid = File.read("pids/server.pid").to_i
      puts "Stopping server at pid #{pid}"
      Process.kill("SIGKILL", pid)
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
end
