module Auditing
  # namespace of the PostgreSQL-level settings that are read and written using
  # `set_config` and `current_setting`.
  PG_SETTING_PREFIX = "audit"
  private_constant :PG_SETTING_PREFIX

  TRANSACTION_LEVEL_KEYS = Set[:actor, :entrypoint, :trace_id]
  private_constant :TRANSACTION_LEVEL_KEYS

  extend self

  def set_database_transaction_context(connection:)
    set_auditing_opts(
      connection:,
      transaction_local: true,
      values: {
        actor: Current.user&.id,
        entrypoint: Current.entrypoint,
        trace_id: Current.trace_id
      }
    )
  end

  private

  # @param transaction_local [Boolean]
  #   false = persists for the connection
  #   true = local to the transaction
  def set_auditing_opts(connection:, transaction_local:, values:)
    # Currently the only use of this method is for transaction-local settings.
    # If we do introduce connection-level settings, it's important to keep those
    # managed separately and explicitly so we don't end up accidentally storing
    # things in the wrong place e.g. a trace_id at the connection-level.
    audit_opts = if transaction_local
      values.slice(*TRANSACTION_LEVEL_KEYS)
    else
      raise NotImplementedError, "connection-level attributes are not supported"
    end

    return if audit_opts.empty?

    # set_config(name text, value text, is_local bool)
    setters = audit_opts.map do |key, value|
      args = ["#{PG_SETTING_PREFIX}.#{key}", value, transaction_local].map { connection.quote(it) }
      format("set_config(%s, %s, %s)", *args)
    end

    connection.execute("SELECT #{setters.join(", ")}", "Auditing")
  end
end
