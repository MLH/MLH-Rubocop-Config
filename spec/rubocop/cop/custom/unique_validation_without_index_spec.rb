# frozen_string_literal: true

require 'tmpdir'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../lib/custom/unique_validation_without_index'

RSpec.describe RuboCop::Cop::Custom::UniqueValidationWithoutIndex, :config do
  include RuboCop::RSpec::ExpectOffense

  let(:structure) do
    <<~SQL
      CREATE TABLE public.accounts (
          id bigint NOT NULL,
          team_id bigint,
          email character varying(255) NOT NULL,
          code text,
          token text,
          seat integer
      );

      ALTER TABLE ONLY public.accounts
          ADD CONSTRAINT accounts_token_key UNIQUE (token);

      CREATE INDEX index_accounts_on_seat ON public.accounts USING btree (seat);
      CREATE UNIQUE INDEX index_accounts_on_email ON public.accounts USING btree (email, team_id);
      CREATE UNIQUE INDEX index_accounts_on_code ON public.accounts USING btree (lower(code)) WHERE (code IS NOT NULL);
    SQL
  end

  around do |example|
    Dir.mktmpdir do |directory|
      Dir.mkdir(File.join(directory, 'db'))
      File.write(File.join(directory, 'db/structure.sql'), structure) if structure
      described_class::Schema.instance_variable_set(:@load, nil)
      Dir.chdir(directory) { example.run }
    end
  end

  def model(validation)
    <<~RUBY
      class Account < ApplicationRecord
        belongs_to :team
        #{validation}
      end
    RUBY
  end

  it 'flags a validation on a column with no unique index' do
    expect_offense(<<~RUBY)
      class Account < ApplicationRecord
        validates :seat, uniqueness: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Uniqueness validation should have a unique index on the database column.
      end
    RUBY
  end

  it 'accepts a unique index on the validated columns, resolving a belongs_to scope' do
    expect_no_offenses(model('validates :email, uniqueness: { scope: :team }'))
  end

  it 'accepts a unique constraint and an expression index' do
    expect_no_offenses(model('validates :token, uniqueness: true'))
    expect_no_offenses(model('validates :code, uniqueness: { case_sensitive: false }'))
  end

  context 'without a db/structure.sql' do
    let(:structure) { nil }

    it 'checks nothing' do
      expect_no_offenses(model('validates :seat, uniqueness: true'))
    end
  end
end
