CREATE SCHEMA audit;

CREATE TYPE audit.operation AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE'
);

CREATE FUNCTION audit.disable_auditing(table_name regclass) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
declare
  drop1 text = format('drop trigger if exists audit_u on %s', $1);
  drop2 text = format('drop trigger if exists audit_i_d on %s', $1);
begin
  execute drop1;
  execute drop2;
end;
$_$;

CREATE FUNCTION audit.enable_auditing(table_name regclass, except_cols name[] DEFAULT '{id}'::name[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
declare
  update_trigger text = format('
    create or replace trigger audit_u
      after update
      on %s
      for each row
      when (old.* is distinct from new.*)
      execute function audit.insert_update_delete_trigger(%L);',
      $1, $2
  );

  insert_delete_trigger text = format('
    create or replace trigger audit_i_d
      after insert or delete
      on %s
      for each row
      execute function audit.insert_update_delete_trigger(%L);',
      $1, $2
  );

  pkey_cols text[] = audit.primary_key_columns($1);
begin
  if pkey_cols = array[]::text[] then
    raise exception 'Table %s cannot be audited because it has no primary key', $1;
  end if;

  execute update_trigger;
  execute insert_delete_trigger;
end;
$_$;

CREATE FUNCTION audit.insert_update_delete_trigger() RETURNS trigger
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

CREATE FUNCTION audit.jsonb_diff(a jsonb, b jsonb) RETURNS TABLE(attribute name, old jsonb, new jsonb)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $_$
declare
  keys record;
begin
  for keys in (
    select a.k from jsonb_object_keys($1) a(k)
    union distinct
    select b.k from jsonb_object_keys($2) b(k)
  ) loop
    attribute := keys.k;
    old = a->attribute;
    new = b->attribute;
    if old is distinct from new then
      return next;
    end if;
  end loop;
end
$_$;

CREATE FUNCTION audit.jsonb_diff_as_object(a jsonb, b jsonb) RETURNS jsonb
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  -- given two jsonb objects, return a new object with keys that changed
  -- and the old and new values in an array e.g. {"a": ["oldval", "newval"]}
  select jsonb_object_agg(x.col, x.changes)
  from (
    select
      attribute as col,
      jsonb_build_array(old, new) as changes
    from audit.jsonb_diff(a, b)
  ) as x
$$;

CREATE FUNCTION audit.primary_key_columns(entity_oid oid) RETURNS text[]
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $_$
  select
    coalesce(
      array_agg(pa.attname::text order by pa.attnum),
      array[]::text[]
    ) as column_names
  from
    pg_index pi
    inner join pg_attribute pa
      on pi.indrelid = pa.attrelid
      and pa.attnum = any(pi.indkey)
  where
    indrelid = $1
    and indisprimary
$_$;


CREATE FUNCTION audit.to_record_id(entity_oid oid, pkey_cols text[], rec jsonb) RETURNS text
    LANGUAGE sql STABLE
    AS $_$
  select
    case
      when rec is null then null
      when array_length($2, 1) = 1 then $3->>$2[1]
      else (
        select jsonb_object_agg(attr, $3->>attr)::text
        from unnest($2) x(attr)
      )
    end
$_$;

CREATE TABLE audit.logs (
    id            uuid NOT NULL DEFAULT uuidv7() PRIMARY KEY,
    op            audit.operation NOT NULL,
    ts            timestamp with time zone generated always as (uuid_extract_timestamp(id)) stored,
    table_oid     oid NOT NULL,
    table_schema  name NOT NULL,
    table_name    name NOT NULL,
    record_id     text,
    diff          jsonb,
    actor         character varying(255),
    entrypoint    character varying(255),
    trace_id      character varying(255),
    application   character varying(255),
    CONSTRAINT logs_check CHECK (((op = 'TRUNCATE'::audit.operation) OR (record_id IS NOT NULL))),
    CONSTRAINT logs_record_id_required CHECK (((op = ANY (ARRAY['INSERT'::audit.operation, 'UPDATE'::audit.operation, 'DELETE'::audit.operation])) = (record_id IS NOT NULL)))
);
CREATE INDEX ix_logs_actor ON audit.logs USING btree (actor);
CREATE INDEX ix_logs_entrypoint ON audit.logs USING btree (entrypoint);
CREATE INDEX ix_logs_op ON audit.logs USING btree (op);
CREATE INDEX ix_logs_table_name_and_record_id ON audit.logs USING btree (table_name, record_id);
CREATE INDEX ix_logs_ts ON audit.logs USING btree (ts);
