# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../lib/custom/rails_env_in_model'

RSpec.describe RuboCop::Cop::Custom::RailsEnvInModel, :config do
  include RuboCop::RSpec::ExpectOffense

  it 'flags a Rails.env predicate' do
    expect_offense(<<~RUBY)
      return refresh! unless Rails.env.production?
                             ^^^^^^^^^ Models do not branch on Rails.env; move the environment-specific behavior to the service or lib layer the model delegates to.
    RUBY
  end

  it 'flags a top-level Rails.env comparison' do
    expect_offense(<<~RUBY)
      skip_verification = ::Rails.env == 'development'
                          ^^^^^^^^^^^ Models do not branch on Rails.env; move the environment-specific behavior to the service or lib layer the model delegates to.
    RUBY
  end

  it 'accepts other Rails calls and env on other receivers' do
    expect_no_offenses(<<~RUBY)
      Rails.logger.warn(message)
      Rails.application.config.x.customer_io
      request.env['HTTP_HOST']
    RUBY
  end
end
