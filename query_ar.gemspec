# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'query_ar/version'

Gem::Specification.new do |spec|
  spec.name          = "query_ar"
  spec.version       = QueryAr::VERSION
  spec.authors       = ["Stuart Liston"]
  spec.email         = ["stuart.liston@gmail.com"]
  spec.description   = %q{ Query AR models with ease }
  spec.summary       = %q{ Gives you a DSL to build filtered, scoped, paged and sorted ActiveRecord queries, based on a parameters hash. }
  spec.homepage      = "http://github.com/hooroo/query_ar"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"

  spec.add_runtime_dependency "activesupport", "~> 4.0.1"
end
