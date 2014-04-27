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
    playerid bigint,
    "time" timestamp with time zone,
    id integer NOT NULL
);


--
-- Name: deaths_pve; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deaths_pve (
);


--
-- Name: deaths_pvp; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deaths_pvp (
    killerid bigint,
    id integer NOT NULL
);


--
-- Name: instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE instances (
    instanceid character varying(26) NOT NULL
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
    servername character varying(100),
    serverid character varying(26) NOT NULL,
    secretkey uuid NOT NULL
);


--
-- Name: deaths_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths
    ADD CONSTRAINT deaths_pkey PRIMARY KEY (id);


--
-- Name: deaths_pvp_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths_pvp
    ADD CONSTRAINT deaths_pvp_pkey PRIMARY KEY (id);


--
-- Name: players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: servers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY servers
    ADD CONSTRAINT servers_pkey PRIMARY KEY (serverid);


--
-- Name: playerid_fkey; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX playerid_fkey ON deaths USING btree (playerid);


--
-- Name: servers_secretkey_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX servers_secretkey_idx ON servers USING btree (secretkey);


--
-- Name: deaths_playerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths
    ADD CONSTRAINT deaths_playerid_fkey FOREIGN KEY (playerid) REFERENCES players(id);


--
-- Name: deaths_pvp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deaths_pvp
    ADD CONSTRAINT deaths_pvp_id_fkey FOREIGN KEY (id) REFERENCES deaths(id);


--
-- PostgreSQL database dump complete
--

