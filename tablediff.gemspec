lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'table_diff/version'

Gem::Specification.new do |spec|
  spec.name          = "tablediff"
  spec.version       = TableDiff::VERSION
  spec.authors       = ["Scott Bronson"]
  spec.email         = ["brons_tablediff@rinspin.com"]
  spec.summary       = %q{Take snapshots of database tables and compute the differences between two snapshots.}
  # spec.description   = %q{}
  spec.homepage      = "https://github.com/bronson/tablediff"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "guard-rspec"
end
