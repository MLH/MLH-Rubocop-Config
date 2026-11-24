# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # Flags `Rails.env` in models, which should delegate environment-specific behavior.
      class RailsEnvInModel < Base
        MSG = 'Models do not branch on Rails.env; move the environment-specific behavior to the service or ' \
              'lib layer the model delegates to.'
        RESTRICT_ON_SEND = [:env].freeze

        def_node_matcher :rails_env?, '(send (const {nil? cbase} :Rails) :env)'

        def on_send(node)
          add_offense(node) if rails_env?(node)
        end
      end
    end
  end
end
