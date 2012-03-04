# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "kajax"
  gem.homepage = "http://github.com/haracane/kajax"
  gem.license = "MIT"
  gem.summary = %Q{ruby extensions for kick start}
  gem.description = %Q{ruby extensions for kick start}
  gem.email = "hara@mail.com"
  gem.authors = ["Kenji Hara"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "kajax #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'ci/reporter/rake/rspec'     # use this if you're using RSpec
#require 'ci/reporter/rake/cucumber'  # use this if you're using Cucumber
#require 'ci/reporter/rake/test_unit' # use this if you're using Test::Unit
#require 'ci/reporter/rake/minitest' # use this if you're using MiniTest::Unit