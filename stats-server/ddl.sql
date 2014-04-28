--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_with_oids = false;

--
-- Name: deaths; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deaths (
    player_id bigint NOT NULL,
    "time" timestamp with time zone NOT NULL,
    instance_id uuid NOT NULL,
    id uuid NOT NULL
);


--
-- Name: deaths_pve; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deaths_pve (
    id uuid NOT NULL,
    killer_name character varying(26) NOT NULL
);


--
-- Name: deaths_pvp; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deaths_pvp (
    killerid bigint,
    id uuid NOT NULL
);


--
-- Name: instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE instances (
    id uuid NOT NULL,
    url_id character varying NOT NULL,
    server_id uuid NOT NULL,
    name character varying(26) NOT NULL
);


--
-- Name: players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE players (
    id bigint NOT NULL,
    name character varying(32) NOT NULL
);


--
-- Name: servers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE servers (
    name character varying(100),
    url_id character varying(26) NOT NULL,
    id uuid NOT NULL
);


--
-- Name: deaths_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths
    ADD CONSTRAINT deaths_pkey PRIMARY KEY (id);


--
-- Name: deaths_pve_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths_pve
    ADD CONSTRAINT deaths_pve_pkey PRIMARY KEY (id);


--
-- Name: deaths_pvp_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths_pvp
    ADD CONSTRAINT deaths_pvp_pkey PRIMARY KEY (id);


--
-- Name: instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: instances_server_id_url_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instances
    ADD CONSTRAINT instances_server_id_url_id_key UNIQUE (server_id, url_id);


--
-- Name: players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: servers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY servers
    ADD CONSTRAINT servers_pkey PRIMARY KEY (id);


--
-- Name: servers_url_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY servers
    ADD CONSTRAINT servers_url_id_key UNIQUE (url_id);


--
-- Name: deaths_instances_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX deaths_instances_fk ON deaths USING btree (instance_id);


--
-- Name: deaths_players_fkey; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX deaths_players_fkey ON deaths USING btree (player_id);


--
-- Name: instances_servers_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instances_servers_fk ON instances USING btree (server_id);


--
-- Name: servers_url_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX servers_url_id_idx ON servers USING btree (url_id);


--
-- Name: deaths_instance_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths
    ADD CONSTRAINT deaths_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES instances(id);


--
-- Name: deaths_playerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths
    ADD CONSTRAINT deaths_playerid_fkey FOREIGN KEY (player_id) REFERENCES players(id);


--
-- Name: deaths_pve_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths_pve
    ADD CONSTRAINT deaths_pve_id_fkey FOREIGN KEY (id) REFERENCES deaths(id);


--
-- Name: deaths_pvp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths_pvp
    ADD CONSTRAINT deaths_pvp_id_fkey FOREIGN KEY (id) REFERENCES deaths(id);


--
-- Name: instances_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY instances
    ADD CONSTRAINT instances_server_id_fkey FOREIGN KEY (server_id) REFERENCES servers(id);


--
-- PostgreSQL database dump complete
--

