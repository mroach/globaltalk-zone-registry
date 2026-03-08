class FixAuditDelete < ActiveRecord::Migration[8.1]
  def up
    execute(<<~SQL)
    CREATE or replace FUNCTION audit.insert_update_delete_trigger() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
      declare
        -- TG_RELID: object ID of the table that caused the trigger invocation
        pkey_cols text[] = audit.primary_key_columns(TG_RELID);

        except_cols       name[] = coalesce(TG_ARGV[0], '{}')::name[];

        record_jsonb      jsonb = to_jsonb(new);
        record_id         text  = audit.to_record_id(TG_RELID, pkey_cols, record_jsonb);

        old_record_jsonb  jsonb = to_jsonb(old);
        old_record_id     text  = audit.to_record_id(TG_RELID, pkey_cols, old_record_jsonb);
        diff_jsonb        jsonb = audit.jsonb_diff_as_object(old_record_jsonb, record_jsonb) - except_cols;
      begin
        insert into audit.logs(
          op,
          table_oid,
          table_schema,
          table_name,

          record_id,

          diff,

          actor,
          entrypoint,
          trace_id,
          application
        )
        select
          TG_OP::audit.operation,
          TG_RELID,
          TG_TABLE_SCHEMA,
          TG_TABLE_NAME,

          coalesce(record_id, old_record_id),
          diff_jsonb,

          -- values that might come from connection or transaction-local variables
          current_setting('audit.actor', true),
          current_setting('audit.entrypoint', true),
          current_setting('audit.trace_id', true),
          current_setting('application_name', true)
        where
          -- if all changed columns were excluded from auditing, don't log anything
          (diff_jsonb is not null and diff_jsonb::text <> '{}')
        ;

        return coalesce(new, old);
      end;
      $$;

      alter table audit.logs drop constraint logs_record_id_required;
      alter table audit.logs add constraint logs_record_id_required check (
        (op = any(array[
          'INSERT'::audit.operation,
          'UPDATE'::audit.operation,
          'DELETE'::audit.operation
        ])) = (record_id is not null)
      );
    SQL
  end

  def down
    :noop
  end
end
