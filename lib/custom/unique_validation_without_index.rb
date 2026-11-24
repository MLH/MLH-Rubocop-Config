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
      # A partial unique index counts only when its WHERE leaves out NULLs of an indexed column.
      #
      # @example
      #   # bad - accounts has no unique index on email
      #   validates :email, uniqueness: true
      class UniqueValidationWithoutIndex < RuboCop::Cop::Rails::UniqueValidationWithoutIndex
        # db/structure.sql in the shape the Rails cop reads from db/schema.rb.
        class Schema
          NAME = /((?:\w+\.)?"?\w+"?)/
          TABLE = /^CREATE TABLE #{NAME} \((.*?)^\)/m
          COLUMN = /^\s+"?(\w+)"? /
          OPTIONS = /(?: (?:INCLUDE|NULLS|WITH) [^;]*?)?(?: WHERE (.*))?/
          INDEX = /^CREATE UNIQUE INDEX \S+ ON (?:ONLY )?#{NAME} USING \w+ \((.*?)\)#{OPTIONS};$/
          CONSTRAINT = /^ALTER TABLE (?:ONLY )?#{NAME}\s+ADD CONSTRAINT \S+ UNIQUE(?: NULLS [A-Z ]+)? \((.*?)\)/
          NOT_NULL = /\A(\w+) IS NOT NULL\z/

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

          # The parsed file, read again when it changes.
          def self.load
            file = path
            key = file && [file, file.mtime]
            @load = [key, file && new(file.read)] unless @load&.first == key
            @load.last
          end

          def initialize(sql)
            @tables = sql.scan(TABLE).to_h do |name, body|
              [name.delete('"'), Table.new(name, body.scan(COLUMN).flatten.map { |column| Column.new(column) }, [])]
            end
            (sql.scan(INDEX) + sql.scan(CONSTRAINT)).each do |table, keys, where|
              @tables[table.delete('"')]&.indices&.push(index(keys)) if every_row?(keys, where)
            end
          end

          # A table by the name a model gives it: schema-qualified, or bare for one in public.
          def table_by(name:)
            @tables[name] || @tables["public.#{name}"]
          end

          def add_indices_by(**)
            []
          end

          private

          # A key list of plain columns, each with any ordering or operator class dropped, or an
          # expression such as lower((email)::text).
          def index(keys)
            plain = keys.match?(/\A[\w", ]+\z/)
            Index.new(plain ? keys.split(', ').map { |key| key[/\w+/] } : [], plain ? nil : keys, true)
          end

          # A partial index holds for every row a validation compares only when its WHERE leaves
          # out nothing but NULLs of the columns it indexes, which never collide.
          def every_row?(keys, where)
            where.to_s.delete('()"').split(' AND ').all? do |term|
              (column = term[NOT_NULL, 1]) && keys.match?(/\b#{column}\b/)
            end
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
