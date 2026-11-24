# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # Flags `Rails.env` in models, which should delegate environment-specific behavior.
      # A method named in AllowedMethods may keep the branch it already has.
      class RailsEnvInModel < Base
        include AllowedMethods

        MSG = 'Models do not branch on Rails.env; move the environment-specific behavior to the service or ' \
              'lib layer the model delegates to.'
        RESTRICT_ON_SEND = [:env].freeze

        def_node_matcher :rails_env?, '(send (const {nil? cbase} :Rails) :env)'

        def on_send(node)
          return unless rails_env?(node)
          return if node.each_ancestor(:def, :defs).any? { |method| allowed_method?(method.method_name) }

          add_offense(node)
        end
      end
    end
  end
end
