module Auditing
  module Controller
    def self.included(base)
      base.include(InstanceMethods)
      base.before_action(:set_auditing_context)
    end

    module InstanceMethods
      private

      def set_auditing_context
        Current.trace_id = request.request_id
        Current.entrypoint = "http:#{controller_name}##{action_name}"
      end
    end
  end
end
