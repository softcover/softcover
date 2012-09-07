#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Polytexnic::Application.load_tasks

require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

desc "Run RSpec"
#RSpec::Core::RakeTask.new do |t|
  #t.verbose = false
#end

task :default => :spec
