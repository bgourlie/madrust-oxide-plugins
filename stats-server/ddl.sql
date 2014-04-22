--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

ALTER TABLE ONLY public.deaths_pvp DROP CONSTRAINT deaths_pvp_id_fkey;
ALTER TABLE ONLY public.deaths DROP CONSTRAINT deaths_playerid_fkey;
DROP INDEX public.playerid_fkey;
ALTER TABLE ONLY public.servers DROP CONSTRAINT servers_pkey;
ALTER TABLE ONLY public.players DROP CONSTRAINT players_pkey;
ALTER TABLE ONLY public.deaths_pvp DROP CONSTRAINT deaths_pvp_pkey;
ALTER TABLE ONLY public.deaths DROP CONSTRAINT deaths_pkey;
DROP TABLE public.servers;
DROP TABLE public.players;
DROP TABLE public.deaths_pvp;
DROP TABLE public.deaths_pve;
DROP TABLE public.deaths;
DROP EXTENSION plpgsql;
DROP SCHEMA public;
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: brian
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO brian;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: brian
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: deaths; Type: TABLE; Schema: public; Owner: brian; Tablespace: 
--

CREATE TABLE deaths (
    playerid bigint,
    "time" timestamp with time zone,
    id integer NOT NULL
);


ALTER TABLE public.deaths OWNER TO brian;

--
-- Name: deaths_pve; Type: TABLE; Schema: public; Owner: brian; Tablespace: 
--

CREATE TABLE deaths_pve (
);


ALTER TABLE public.deaths_pve OWNER TO brian;

--
-- Name: deaths_pvp; Type: TABLE; Schema: public; Owner: brian; Tablespace: 
--

CREATE TABLE deaths_pvp (
    killerid bigint,
    id integer NOT NULL
);


ALTER TABLE public.deaths_pvp OWNER TO brian;

--
-- Name: players; Type: TABLE; Schema: public; Owner: brian; Tablespace: 
--

CREATE TABLE players (
    id bigint NOT NULL,
    name character varying(32) NOT NULL
);


ALTER TABLE public.players OWNER TO brian;

--
-- Name: servers; Type: TABLE; Schema: public; Owner: brian; Tablespace: 
--

CREATE TABLE servers (
    serverid uuid NOT NULL,
    servername character varying(100)
);


ALTER TABLE public.servers OWNER TO brian;

--
-- Name: deaths_pkey; Type: CONSTRAINT; Schema: public; Owner: brian; Tablespace: 
--

ALTER TABLE ONLY deaths
    ADD CONSTRAINT deaths_pkey PRIMARY KEY (id);


--
-- Name: deaths_pvp_pkey; Type: CONSTRAINT; Schema: public; Owner: brian; Tablespace: 
--

ALTER TABLE ONLY deaths_pvp
    ADD CONSTRAINT deaths_pvp_pkey PRIMARY KEY (id);


--
-- Name: players_pkey; Type: CONSTRAINT; Schema: public; Owner: brian; Tablespace: 
--

ALTER TABLE ONLY players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: servers_pkey; Type: CONSTRAINT; Schema: public; Owner: brian; Tablespace: 
--

ALTER TABLE ONLY servers
    ADD CONSTRAINT servers_pkey PRIMARY KEY (serverid);


--
-- Name: playerid_fkey; Type: INDEX; Schema: public; Owner: brian; Tablespace: 
--

CREATE INDEX playerid_fkey ON deaths USING btree (playerid);


--
-- Name: deaths_playerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brian
--

ALTER TABLE ONLY deaths
    ADD CONSTRAINT deaths_playerid_fkey FOREIGN KEY (playerid) REFERENCES players(id);


--
-- Name: deaths_pvp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brian
--

ALTER TABLE ONLY deaths_pvp
    ADD CONSTRAINT deaths_pvp_id_fkey FOREIGN KEY (id) REFERENCES deaths(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: brian
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM brian;
GRANT ALL ON SCHEMA public TO brian;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

