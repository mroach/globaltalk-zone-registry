SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: audit; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA audit;


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: operation; Type: TYPE; Schema: audit; Owner: -
--

CREATE TYPE audit.operation AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE'
);


--
-- Name: disable_auditing(regclass); Type: FUNCTION; Schema: audit; Owner: -
--

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


--
-- Name: enable_auditing(regclass, name[]); Type: FUNCTION; Schema: audit; Owner: -
--

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


--
-- Name: insert_update_delete_trigger(); Type: FUNCTION; Schema: audit; Owner: -
--

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


--
-- Name: jsonb_diff(jsonb, jsonb); Type: FUNCTION; Schema: audit; Owner: -
--

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


--
-- Name: jsonb_diff_as_object(jsonb, jsonb); Type: FUNCTION; Schema: audit; Owner: -
--

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


--
-- Name: primary_key_columns(oid); Type: FUNCTION; Schema: audit; Owner: -
--

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


--
-- Name: to_record_id(oid, text[], jsonb); Type: FUNCTION; Schema: audit; Owner: -
--

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


--
-- Name: immutable_record(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.immutable_record() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
  raise exception '% denied on "%". Relation is immutable.',
    TG_OP,
    TG_TABLE_NAME;
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: logs; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.logs (
    id uuid DEFAULT uuidv7() NOT NULL,
    op audit.operation NOT NULL,
    ts timestamp with time zone GENERATED ALWAYS AS (uuid_extract_timestamp(id)) STORED,
    table_oid oid NOT NULL,
    table_schema name NOT NULL,
    table_name name NOT NULL,
    record_id text,
    diff jsonb,
    actor character varying(255),
    entrypoint character varying(255),
    trace_id character varying(255),
    application character varying(255),
    CONSTRAINT logs_check CHECK (((op = 'TRUNCATE'::audit.operation) OR (record_id IS NOT NULL))),
    CONSTRAINT logs_record_id_required CHECK (((op = ANY (ARRAY['INSERT'::audit.operation, 'UPDATE'::audit.operation, 'DELETE'::audit.operation])) = (record_id IS NOT NULL)))
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: endpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.endpoints (
    id uuid DEFAULT uuidv7() CONSTRAINT networks_id_not_null NOT NULL,
    created_at timestamp(6) without time zone CONSTRAINT networks_created_at_not_null NOT NULL,
    updated_at timestamp(6) without time zone CONSTRAINT networks_updated_at_not_null NOT NULL,
    user_id uuid CONSTRAINT networks_user_id_not_null NOT NULL,
    ranges int4range[] DEFAULT '{}'::int4range[] CONSTRAINT networks_ranges_not_null NOT NULL,
    static_endpoint character varying,
    ddns_subdomain public.citext,
    ddns_ip inet,
    ddns_password character varying,
    notes text,
    disabled_at timestamp(6) without time zone
);


--
-- Name: external_zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_zones (
    id uuid DEFAULT uuidv7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    source character varying NOT NULL,
    name public.citext NOT NULL,
    network_ranges int4range[] DEFAULT '{}'::int4range[] NOT NULL,
    public_endpoint public.citext,
    last_lookup_result character varying,
    last_lookup_at timestamp without time zone,
    last_ip inet
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id uuid DEFAULT uuidv7() NOT NULL,
    user_id uuid NOT NULL,
    ip_address inet,
    user_agent character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT uuidv7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    email_address character varying NOT NULL,
    email_confirmed_at timestamp without time zone,
    password_digest character varying NOT NULL,
    name public.citext NOT NULL,
    socials character varying,
    location character varying,
    time_zone character varying DEFAULT 'Etc/UTC'::character varying NOT NULL,
    roles character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    slug character varying NOT NULL
);


--
-- Name: zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zones (
    id uuid DEFAULT uuidv7() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id uuid NOT NULL,
    name public.citext NOT NULL,
    about text,
    approved_at timestamp without time zone,
    admin_notes text
);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: external_zones external_zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_zones
    ADD CONSTRAINT external_zones_pkey PRIMARY KEY (id);


--
-- Name: endpoints networks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.endpoints
    ADD CONSTRAINT networks_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: ix_logs_actor; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX ix_logs_actor ON audit.logs USING btree (actor);


--
-- Name: ix_logs_entrypoint; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX ix_logs_entrypoint ON audit.logs USING btree (entrypoint);


--
-- Name: ix_logs_op; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX ix_logs_op ON audit.logs USING btree (op);


--
-- Name: ix_logs_table_name_and_record_id; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX ix_logs_table_name_and_record_id ON audit.logs USING btree (table_name, record_id);


--
-- Name: ix_logs_ts; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX ix_logs_ts ON audit.logs USING btree (ts);


--
-- Name: index_endpoints_on_ranges; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_endpoints_on_ranges ON public.endpoints USING gin (ranges);


--
-- Name: index_endpoints_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_endpoints_on_user_id ON public.endpoints USING btree (user_id);


--
-- Name: index_external_zones_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_external_zones_on_name ON public.external_zones USING btree (name);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: index_users_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_name ON public.users USING btree (name);


--
-- Name: index_users_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_slug ON public.users USING btree (slug);


--
-- Name: index_zones_on_approved_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_approved_at ON public.zones USING btree (approved_at);


--
-- Name: index_zones_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_zones_on_name ON public.zones USING btree (name);


--
-- Name: index_zones_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_user_id ON public.zones USING btree (user_id);


--
-- Name: endpoints audit_i_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_d AFTER INSERT OR DELETE ON public.endpoints FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger('{id,created_at,updated_at}');


--
-- Name: users audit_i_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_d AFTER INSERT OR DELETE ON public.users FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger('{password_digest,id,created_at,updated_at}');


--
-- Name: zones audit_i_d; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_i_d AFTER INSERT OR DELETE ON public.zones FOR EACH ROW EXECUTE FUNCTION audit.insert_update_delete_trigger('{about,id,created_at,updated_at}');


--
-- Name: endpoints audit_u; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_u AFTER UPDATE ON public.endpoints FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE FUNCTION audit.insert_update_delete_trigger('{id,created_at,updated_at}');


--
-- Name: users audit_u; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_u AFTER UPDATE ON public.users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE FUNCTION audit.insert_update_delete_trigger('{password_digest,id,created_at,updated_at}');


--
-- Name: zones audit_u; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_u AFTER UPDATE ON public.zones FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE FUNCTION audit.insert_update_delete_trigger('{about,id,created_at,updated_at}');


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260310231318'),
('20260310165607'),
('20260310154910'),
('20260310121025'),
('20260309214730'),
('20260309182429'),
('20260308083956'),
('20260308082736'),
('20260308065716'),
('20260307223227'),
('20260307164351'),
('20260302223512'),
('20260302203052'),
('20260302203051');

