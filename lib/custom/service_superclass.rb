# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # Flags a service-shaped class with no superclass: one that defines `call` or `call!`
      # itself, or whose name ends in Service and that defines methods. The class name and each
      # `call` are reported, so a diff that adds either one is flagged on the line it adds.
      # A class named in AllowedClasses is left alone.
      class ServiceSuperclass < Base
        MSG = 'Inherit from ApplicationService instead of hand-rolling the entry point on a plain class.'
        ENTRY_POINTS = [:call, :call!].freeze

        def_node_matcher :own_method?, '{def (defs self ...)}'
        def_node_matcher :singleton_body, '(sclass self $_)'
        def_node_matcher :declared_method, '(send nil? {:public :protected :private :private_class_method} $any_def)'

        def on_class(node)
          return if node.parent_class || node.identifier.short_name == :ApplicationService || allowed?(node)

          methods = owned_methods(node)
          entry_points = methods.select { |method| ENTRY_POINTS.include?(method.method_name) }
          return unless entry_points.any? || (service_name?(node) && methods.any?)

          add_offense(node.identifier)
          entry_points.each { |method| add_offense(method.loc.name) }
        end

        private

        # A class named in AllowedClasses by its full name, such as Github::RepoImporter.
        def allowed?(node)
          scopes = [node, *node.each_ancestor(:class, :module)].map(&:identifier)
          scopes = scopes.take(scopes.index(&:absolute?) + 1) if scopes.any?(&:absolute?)
          cop_config.fetch('AllowedClasses', []).include?(scopes.reverse.map(&:const_name).join('::'))
        end

        def service_name?(node)
          node.identifier.short_name.end_with?('Service')
        end

        def owned_methods(node)
          members(node.body).flat_map do |member|
            next members(singleton_body(member)).select(&:def_type?) if singleton_body(member)

            own_method?(member) ? [member] : []
          end
        end

        # The members of a body, each taken out of an inline visibility declaration such as
        # `private def call`.
        def members(body)
          return [] unless body

          (body.begin_type? ? body.children : [body]).map { |member| declared_method(member) || member }
        end
      end
    end
  end
end
