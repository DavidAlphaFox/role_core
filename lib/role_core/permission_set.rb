# frozen_string_literal: true

module RoleCore
  class PermissionSet < OptionsModel::Base
    def permitted_permission_names
      attributes.select { |_, v| v }.keys
    end

    def permitted_permissions(include_nested: true)
      permissions = self.class.registered_permissions.slice(*permitted_permission_names).values
      if include_nested && nested_attributes.any?
        permissions.concat nested_attributes.values.map(&:permitted_permissions).flatten!
      end

      ComputedPermissions.new(permissions)
    end

    class << self
      def i18n_scope
        :role_core
      end

      def permission_class
        @permission_class || RoleCore.permission_class
      end

      def permission_class=(klass)
        unless klass && klass < Permission
          raise ArgumentError, "#{klass} should be sub-class of #{Permission}."
        end

        @permission_class = klass
      end

      def draw(**constraints, &block)
        unless block_given?
          raise ArgumentError, "must provide a block"
        end

        Mapper.new(self, constraints).instance_exec(&block)

        self
      end

      def registered_permissions
        @registered_permissions ||= ActiveSupport::HashWithIndifferentAccess.new
      end

      def register_permission(name, default = false, **options, &block)
        raise ArgumentError, "`name` can't be blank" if name.blank?

        attribute name, :boolean, default: default
        registered_permissions[name] = permission_class.new name, options, &block
      end
    end
  end
end
