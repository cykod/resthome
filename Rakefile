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
  gem.name = "resthome"
  gem.homepage = "http://github.com/cykod/resthome"
  gem.license = "MIT"
  gem.summary = %Q{RESTful web services consumer}
  gem.description = %Q{Simple wrapper class generator for consuming RESTful web services}
  gem.email = "doug@cykod.com"
  gem.authors = ["Doug Youch"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  gem.add_runtime_dependency 'httparty', '>= 0'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
  gem.add_development_dependency "bundler", "~> 1.0.0"
  gem.add_development_dependency "jeweler", "~> 1.5.1"
  gem.add_development_dependency "rcov", ">= 0"
  gem.add_development_dependency "fakeweb", ">= 0"
  gem.add_development_dependency "json", ">= 0"
  gem.add_development_dependency "rspec", ">= 0"
end
Jeweler::RubygemsDotOrgTasks.new

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "resthome #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

for file in Dir['tasks/*.rake']
  load file
end
