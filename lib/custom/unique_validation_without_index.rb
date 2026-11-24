# frozen_string_literal: true

require 'digest'
require 'pathname'
require 'rubocop-rails'

module RuboCop
  module Cop
    module Custom
      # Rails/UniqueValidationWithoutIndex for an app that keeps db/structure.sql. The Rails cop
      # reads db/schema.rb and checks nothing without one. This one applies the same rule to the
      # tables and unique indexes of a PostgreSQL db/structure.sql, and does nothing without one.
      #
      # @example
      #   # bad - accounts has no unique index on email
      #   validates :email, uniqueness: true
      class UniqueValidationWithoutIndex < RuboCop::Cop::Rails::UniqueValidationWithoutIndex
        # db/structure.sql in the shape the Rails cop reads from db/schema.rb.
        class Schema
          TABLE = /^CREATE TABLE (?:\w+\.)?"?(\w+)"? \((.*?)^\)/m
          COLUMN = /^\s+"?(\w+)"? /
          INDEX = /^CREATE UNIQUE INDEX \S+ ON (?:ONLY )?(?:\w+\.)?"?(\w+)"? USING \w+ \((.*?)\)(?: [A-Z].*)?;$/
          CONSTRAINT = /^ALTER TABLE (?:ONLY )?(?:\w+\.)?"?(\w+)"?\s+ADD CONSTRAINT \S+ UNIQUE \((.*?)\)/

          Column = Struct.new(:name)
          Index = Struct.new(:columns, :expression, :unique)
          Table = Struct.new(:name, :columns, :indices) do
            def with_column?(name:)
              columns.any? { |column| column.name == name }
            end
          end

          def self.path
            Pathname.pwd.ascend.map { |directory| directory.join('db/structure.sql') }.find(&:exist?)
          end

          def self.load
            @load ||= path&.then { |file| new(file.read) }
          end

          def initialize(sql)
            @tables = sql.scan(TABLE).to_h do |name, body|
              [name, Table.new(name, body.scan(COLUMN).flatten.map { |column| Column.new(column) }, [])]
            end
            (sql.scan(INDEX) + sql.scan(CONSTRAINT)).each { |table, keys| @tables[table]&.indices&.push(index(keys)) }
          end

          def table_by(name:)
            @tables[name]
          end

          def add_indices_by(**)
            []
          end

          private

          # A key list of plain columns, or an expression such as lower((email)::text).
          def index(keys)
            plain = keys.match?(/\A[\w", ]+\z/)
            Index.new(plain ? keys.delete('"').split(', ') : [], plain ? nil : keys, true)
          end
        end

        def external_dependency_checksum
          path = Schema.path
          path && Digest::SHA1.hexdigest(path.read)
        end

        private

        def schema
          Schema.load
        end
      end
    end
  end
end
