# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sequel_deep_dup/version'

Gem::Specification.new do |spec|
  spec.name          = "sequel_deep_dup"
  spec.version       = Sequel::Plugins::DeepDup::VERSION
  spec.authors       = ["macario"]
  spec.email         = ["mail@makarius.me"]
  spec.summary       = %q{Makes deep copies of existing sequel models into a new record, along with its association tree}
  spec.description   = %q{Makes deep copies of existing sequel models into a new record, along with its association tree}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
