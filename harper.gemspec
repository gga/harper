# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "harper/version"

Gem::Specification.new do |s|
  s.name        = "harper"
  s.version     = Harper::Version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Giles Alexander"]
  s.email       = ["giles.alexander@gmail.com"]
  s.homepage    = "http://github.com/gga/harper"
  s.summary     = %q{Dead simple mocking for HTTP services}
  s.description = %q{Dead simple mocking for HTTP services, a Sinatra app}

  s.rubyforge_project = "harper"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "sinatra", ">= 1.0.0"
  s.add_dependency "httparty"
  s.add_dependency "json", ">= 1.4.6"
  s.add_dependency "trollop"

  s.add_development_dependency "rack-test"
  s.add_development_dependency "sham_rack"
  s.add_development_dependency "rspec"
  s.add_development_dependency "cucumber", ">= 0.10"
  s.add_development_dependency "cucumber-sinatra"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
