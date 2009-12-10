require 'rubygems'
require 'rake'
require File.dirname(__FILE__) + "/lib/bpmachine/version"

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.version = BPMachine::Version::STRING
    gem.name = "bpmachine"
    gem.summary = %Q{Business Process execution engine, with resume support on failures.}
    gem.description = %Q{Includes a DSL for business process specification. The process state is persistent, which allows it to be be resumed if an error occurs.}
    gem.email = "fabio.kung@gmail.com"
    gem.homepage = "http://github.com/fabiokung/bpmachine"
    gem.authors = ["fabiokung"]
    gem.add_dependency "activesupport"
    gem.add_development_dependency "rspec"
    gem.add_development_dependency "cucumber"
    gem.add_development_dependency "spork"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_opts = ["-O", "spec/spec.opts"]
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_opts = ["-O", "spec/spec.opts"]
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.rcov_opts << %w[--exclude spec,activesupport,gems/* --include-file lib/bpmachine.rb,lib/bpmachine/*]
  spec.rcov = true
end

task :spec => :check_dependencies

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)

  task :features => :check_dependencies
rescue LoadError
  task :features do
    abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
  end
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "bpmachine #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
