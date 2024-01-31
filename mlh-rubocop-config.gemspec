# frozen_string_literal: true

require_relative 'lib/mlh-rubocop-config/version'

Gem::Specification.new do |spec|
  spec.name = 'mlh-rubocop-config'
  spec.version = MlhRubocopConfig::VERSION
  spec.authors = ['Major League Hacking (MLH)']
  spec.email = ['hi@mlh.io']
  spec.homepage = 'https://github.com/MLH/MLH-Rubocop-Config'
  spec.summary = 'MLH Rubocop Configuration'
  spec.description = 'MLH Rubocop Config is a customized set of rules and guidelines for Ruby code.'

  spec.files = Dir['{**/}{.*,*}'].select { |path| File.file?(path) && path !~ /^(?:pkg|build)/ }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'rubocop'
  spec.add_dependency 'rubocop-factory_bot'
  spec.add_dependency 'rubocop-performance'
  spec.add_dependency 'rubocop-rails'
  spec.add_dependency 'rubocop-rspec'
end
