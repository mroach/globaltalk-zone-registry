class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true

  attribute :trace_id, default: -> { SecureRandom.uuid_v7 }
  attribute :entrypoint
end
