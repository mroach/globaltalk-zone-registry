# frozen_string_literal: true

module Auditing
  module Model
    def self.included(base)
      base.instance_eval do
        def audited
          extend(ClassMethods)
          include(InstanceMethods)
        end

        private_class_method(:audited)
      end
    end

    module ClassMethods
      def audit_logs
        Auditing::Log.where(table_name:)
      end
    end

    module InstanceMethods
      def audit_logs
        self.class.audit_logs.where(record_id: id)
      end
    end
  end
end
