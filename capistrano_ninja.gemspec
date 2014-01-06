# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano_ninja/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano_ninja"
  spec.version       = CapistranoNinja::VERSION
  spec.authors       = ["akima"]
  spec.email         = ["akima@groovenauts.jp"]
  spec.description   = %q{transport capistrano log to ninja}
  spec.summary       = %q{transport capistrano log to ninja}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "capistrano"   , "~> 2.15.5"
  spec.add_runtime_dependency "fluent-logger", "~> 0.4.5"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
