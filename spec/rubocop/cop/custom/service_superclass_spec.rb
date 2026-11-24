# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../lib/custom/service_superclass'

RSpec.describe RuboCop::Cop::Custom::ServiceSuperclass, :config do
  include RuboCop::RSpec::ExpectOffense

  it 'flags a hand-rolled class-level call on the class and each call' do
    expect_offense(<<~RUBY)
      module Github
        class RepoImporter
              ^^^^^^^^^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
          def self.call(project)
                   ^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
            new(project).call
          end

          def call; end
              ^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
        end
      end
    RUBY
  end

  it 'flags call defined on the singleton class or the instance' do
    expect_offense(<<~RUBY)
      class Evaluator
            ^^^^^^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
        class << self
          def call!(record)
              ^^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
            new(record).call!
          end
        end
      end

      class CountryHint
            ^^^^^^^^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
        def call; end
            ^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
      end
    RUBY
  end

  it 'flags a plain class named Service with its own entry point, on the class or its singleton class' do
    expect_offense(<<~RUBY)
      class EyntkSchedulerService
            ^^^^^^^^^^^^^^^^^^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
        def schedule; end
      end

      class ReminderService
            ^^^^^^^^^^^^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
        def self.schedule; end
      end

      class DigestService
            ^^^^^^^^^^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
        class << self
          def schedule; end
        end
      end
    RUBY
  end

  it 'flags a nested service under a namespace reopening, and not the namespace' do
    expect_offense(<<~RUBY)
      class PromoCode
        module Claim
          class RedemptionService
                ^^^^^^^^^^^^^^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
            def call; end
                ^^^^ Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.
          end
        end
      end
    RUBY
  end

  it 'accepts subclasses, including of other services' do
    expect_no_offenses(<<~RUBY)
      class InviteService < ApplicationService
        def call; end
      end

      class RoleLookupService < ::DiscordService
        def call!; end
      end
    RUBY
  end

  it 'accepts namespaces, error classes, value objects, Structs and Data' do
    expect_no_offenses(<<~RUBY)
      class EventStaff
        class IssuePromoCodeService < ApplicationService
          class SelectionRequired < Errorable::Unprocessable; end

          def call; end
        end
      end

      class OrganizationMergingService
        class ConcurrentMergeConflict < StandardError; end
      end

      class ImportStats
        def initialize
          @processed = 0
        end

        def to_h
          { processed: @processed }
        end
      end

      Result = Struct.new(:value) do
        def call
          value
        end
      end

      Point = Data.define(:x) do
        def call
          x
        end
      end

      class Row < Struct.new(:cells)
        def call
          cells
        end
      end
    RUBY
  end

  it 'accepts call defined by a value object nested in the singleton class' do
    expect_no_offenses(<<~RUBY)
      class Matcher
        class << self
          Result = Data.define(:value) do
            def call
              value
            end
          end
        end

        def match(value)
          Result.new(value)
        end
      end
    RUBY
  end

  it 'accepts call defined on another object' do
    expect_no_offenses(<<~RUBY)
      class Hooks
        def handler.call; end
      end
    RUBY
  end

  it 'accepts ApplicationService itself' do
    expect_no_offenses(<<~RUBY)
      class ApplicationService
        def self.call(*args)
          new(*args).call
        end

        def call
          raise NotImplementedError
        end
      end
    RUBY
  end
end
