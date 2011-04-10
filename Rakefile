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
jeweler_tasks = Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "agrep"
  gem.homepage = "http://github.com/junegunn/agrep"
  gem.license = "MIT"
  gem.summary = %Q{TRE binding for Ruby}
  gem.description = %Q{TRE binding for Ruby}
  gem.email = "junegunn.c@gmail.com"
  gem.authors = ["Junegunn Choi"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'

  # For extensions
  #  http://karottenreibe.github.com/2009/10/25/jeweler-interlude/
  gem.extensions = FileList['ext/**/extconf.rb']
  gem.files.include 'ext/**/*.c'
end
Jeweler::RubygemsDotOrgTasks.new

# For rake-compiler
#  http://karottenreibe.github.com/2009/10/25/jeweler-interlude/
require 'rake/extensiontask'
#jeweler_tasks.gemspec.version = jeweler_tasks.jeweler.version
Rake::ExtensionTask.new('tre', jeweler_tasks.gemspec) do |ext|
	ext.lib_dir = 'lib/agrep'
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "agrep #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
