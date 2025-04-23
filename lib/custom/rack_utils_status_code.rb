# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # This cop checks for uses of `Rack::Utils.status_code` in RSpec tests
      # and suggests using `have_http_status` instead.
      #
      # @example
      #   # bad
      #   expect(response.status).to be(Rack::Utils.status_code(:created))
      #
      #   # good
      #   expect(response).to have_http_status(:created)
      class RackUtilsStatusCode < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Prefer `have_http_status` over `Rack::Utils.status_code`.'

        def_node_matcher :rack_utils_status_code?, <<~PATTERN
          (send 
            (const 
              (const nil? :Rack) :Utils) :status_code $_)
        PATTERN

        def_node_matcher :expect_response_status_pattern?, <<~PATTERN
          (send
            (send nil? :expect
              (send $(send nil? _) :status)
            )
            $_
            (send nil? {:be :eq :eql :equal}
              (send
                (const
                  (const nil? :Rack) :Utils) :status_code $_)))
        PATTERN

        def on_send(node)
          return unless in_rspec_file?(node)

          rack_utils_status_code?(node) do |status_arg|
            add_offense(node, message: MSG) do |corrector|
              parent = node.parent
              
              # Find the expect(...).to be(...) pattern
              expect_node = find_expect_node(parent)
              
              if expect_node
                expect_response_status_pattern?(expect_node) do |response_obj, to_method, status_sym|
                  # Replace just the Rack::Utils.status_code part with have_http_status
                  replacement = "expect(#{response_obj.source}).#{to_method} have_http_status(#{status_sym.source})"
                  corrector.replace(expect_node, replacement)
                end
              end
            end
          end
        end

        private

        # Check if the node is in an RSpec file
        def in_rspec_file?(node)
          file_path = node.location.expression.source_buffer.name
          file_path.end_with?('_spec.rb')
        end

        # Find the expect(...).to be(Rack::Utils.status_code(...)) node
        def find_expect_node(node)
          return nil unless node

          if node.send_type? && 
             (node.method_name == :to || node.method_name == :to_not || node.method_name == :not_to) &&
             node.receiver&.send_type? && 
             node.receiver.method_name == :expect &&
             node.first_argument&.send_type? && 
             (node.first_argument.method_name == :be || 
              node.first_argument.method_name == :eq || 
              node.first_argument.method_name == :eql || 
              node.first_argument.method_name == :equal)
            
            return node
          end

          if node.parent
            find_expect_node(node.parent)
          else
            nil
          end
        end
      end
    end
  end
end