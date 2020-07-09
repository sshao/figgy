# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "figgy/version"

Gem::Specification.new do |s|
  s.name        = "figgy"
  s.version     = Figgy::VERSION
  s.authors     = ["Kyle Hargraves"]
  s.email       = ["pd@krh.me"]
  s.homepage    = "http://github.com/pd/figgy"
  s.summary     = %q{Configuration file reading}
  s.description = %q{Access YAML, JSON (and ...) configuration files with ease}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "json"
  s.add_dependency 'vault', '~> 0.1'
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", '~> 3.0'
  s.add_development_dependency "simplecov", '~> 0.9'
  s.add_development_dependency "heredoc_unindent"
  s.add_development_dependency "pry"
end
