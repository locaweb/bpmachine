# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bpmachine/version"

Gem::Specification.new do |s|
  s.name        = "bpmachine"
  s.version     = BPMachine::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["fabiokung"]
  s.email       = ["fabio.kung@gmail.com"]
  s.homepage    = "http://github.com/fabiokung/bpmachine"
  s.description = %Q{Includes a DSL for business process specification. The process state is persistent, which allows it to be be resumed if an error occurs.}
  s.summary     = s.description

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activesupport"
  s.add_development_dependency "rspec"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "ruby-debug19"
end
