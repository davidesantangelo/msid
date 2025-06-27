# frozen_string_literal: true

require_relative 'lib/msid/version'

Gem::Specification.new do |spec|
  spec.name          = 'msid'
  spec.version       = Msid::VERSION
  spec.authors       = ['Davide Santangelo']
  spec.email         = ['']

  spec.summary       = 'Generates a unique machine fingerprint ID.'
  spec.description   = 'Creates a unique and secure machine fingerprint ID by gathering various system hardware and software identifiers. Designed to be difficult to replicate on another machine.'
  spec.homepage      = 'https://github.com/davidesantangelo/msid'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
