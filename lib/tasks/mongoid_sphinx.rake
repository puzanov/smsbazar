require 'fileutils'
require "config/environment"
require "rubygems"
require "mongoid_sphinx"

namespace :mongoid_sphinx do
  
  desc "Output the current Mongoid Sphinx version"
  task :version => :environment do
    puts "Mongoid Sphinx v" + MongoidSphinx::VERSION
  end
  
  desc "Stop if running, then start a Sphinx searchd daemon using Mongoid Sphinx's settings"
  task :running_start => :environment do
    Rake::Task["mongoid_sphinx:stop"].invoke if sphinx_running?
    Rake::Task["mongoid_sphinx:start"].invoke
  end
  
  desc "Start a Sphinx searchd daemon using Mongoid Sphinx's settings"
  task :start => :environment do
    config = MongoidSphinx::Configuration.instance
    
    FileUtils.mkdir_p config.searchd_file_path
    raise RuntimeError, "searchd is already running." if sphinx_running?
    
    Dir["#{config.searchd_file_path}/*.spl"].each { |file| File.delete(file) }
    
    config.controller.start
    
    if sphinx_running?
      puts "Started successfully (pid #{sphinx_pid})."
    else
      puts "Failed to start searchd daemon. Check #{config.searchd_log_file}"
    end
  end
  
  desc "Stop Sphinx using Mongoid Sphinx's settings"
  task :stop => :environment do
    unless sphinx_running?
      puts "searchd is not running"
    else
      config = MongoidSphinx::Configuration.instance
      pid = sphinx_pid
      config.controller.stop
      puts "Stopped search daemon (pid #{pid})."
    end
  end
  
  desc "Restart Sphinx"
  task :restart => [:environment, :stop, :start]
  
  desc "Generate the Sphinx configuration file using Mongoid Sphinx's settings"
  task :configure => :environment do
    config = MongoidSphinx::Configuration.instance
    puts "Generating Configuration to #{config.config_file}"
    config.build
  end
  
  desc "Index data for Sphinx using Mongoid Sphinx's settings"
  task :index => :environment do
    config = MongoidSphinx::Configuration.instance
    unless ENV["INDEX_ONLY"] == "true"
      puts "Generating Configuration to #{config.config_file}"
      config.build
    end
    
    FileUtils.mkdir_p config.searchd_file_path
    config.controller.index :verbose => true
  end
  
  desc "Reindex Sphinx without regenerating the configuration file"
  task :reindex => :environment do
    config = MongoidSphinx::Configuration.instance
    FileUtils.mkdir_p config.searchd_file_path
    puts config.controller.index
  end
  
  desc "Stop Sphinx (if it's running), rebuild the indexes, and start Sphinx"
  task :rebuild => :environment do
    Rake::Task["mongoid_sphinx:stop"].invoke if sphinx_running?
    Rake::Task["mongoid_sphinx:index"].invoke
    Rake::Task["mongoid_sphinx:start"].invoke
  end
end

namespace :ms do
  desc "Output the current Mongoid Sphinx version"
  task :version => "mongoid_sphinx:version"
  desc "Stop if running, then start a Sphinx searchd daemon using Mongoid Sphinx's settings"
  task :run => "mongoid_sphinx:running_start"
  desc "Start a Sphinx searchd daemon using Mongoid Sphinx's settings"
  task :start => "mongoid_sphinx:start"
  desc "Stop Sphinx using Mongoid Sphinx's settings"
  task :stop => "mongoid_sphinx:stop"
  desc "Index data for Sphinx using Mongoid Sphinx's settings"
  task :in => "mongoid_sphinx:index"
  task :index => "mongoid_sphinx:index"
  desc "Reindex Sphinx without regenerating the configuration file"
  task :reindex => "mongoid_sphinx:reindex"
  desc "Restart Sphinx"
  task :restart => "mongoid_sphinx:restart"
  desc "Generate the Sphinx configuration file using Mongoid Sphinx's settings"
  task :conf => "mongoid_sphinx:configure"
  desc "Generate the Sphinx configuration file using Mongoid Sphinx's settings"
  task :config => "mongoid_sphinx:configure"
  desc "Stop Sphinx (if it's running), rebuild the indexes, and start Sphinx"
  task :rebuild => "mongoid_sphinx:rebuild"
end

def sphinx_pid
  MongoidSphinx.sphinx_pid
end

def sphinx_running?
  MongoidSphinx.sphinx_running?
end


