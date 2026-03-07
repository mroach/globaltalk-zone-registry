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
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET default_tablespace = '';

SET default_table_access_method = heap;

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
    name character varying NOT NULL,
    socials character varying,
    location character varying,
    time_zone character varying DEFAULT 'Etc/UTC'::character varying NOT NULL,
    roles character varying[] DEFAULT '{}'::character varying[] NOT NULL
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
    physical_layer character varying DEFAULT 'ethertalk'::character varying NOT NULL,
    network_ranges int4range[] DEFAULT '{}'::int4range[] NOT NULL,
    static_endpoint character varying,
    about text,
    approved_at timestamp without time zone,
    rejected_at timestamp without time zone,
    disabled_at timestamp without time zone,
    last_verified_at timestamp without time zone,
    ddns_subdomain public.citext,
    ddns_ip inet,
    ddns_password character varying,
    admin_notes text
);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


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
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: index_zones_on_approved_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_approved_at ON public.zones USING btree (approved_at);


--
-- Name: index_zones_on_ddns_subdomain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_zones_on_ddns_subdomain ON public.zones USING btree (ddns_subdomain);


--
-- Name: index_zones_on_disabled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_disabled_at ON public.zones USING btree (disabled_at);


--
-- Name: index_zones_on_last_verified_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_last_verified_at ON public.zones USING btree (last_verified_at);


--
-- Name: index_zones_on_physical_layer_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_zones_on_physical_layer_and_name ON public.zones USING btree (physical_layer, name);


--
-- Name: index_zones_on_rejected_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_rejected_at ON public.zones USING btree (rejected_at);


--
-- Name: index_zones_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zones_on_user_id ON public.zones USING btree (user_id);


--
-- Name: ix_zones_network_ranges; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_zones_network_ranges ON public.zones USING gin (network_ranges);


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
('20260302223512'),
('20260302203052'),
('20260302203051');

