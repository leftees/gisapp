--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.9
-- Dumped by pg_dump version 9.3.9

-- This script does not create database!

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 180 (class 3079 OID 83973)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2121 (class 0 OID 0)
-- Dependencies: 180
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 181 (class 3079 OID 83978)
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;


--
-- TOC entry 2122 (class 0 OID 0)
-- Dependencies: 181
-- Name: EXTENSION intarray; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';


SET search_path = public, pg_catalog;

--
-- TOC entry 203 (class 1255 OID 84089)
-- Name: check_user_project(text, text); Type: FUNCTION; Schema: public; Owner: pguser
--

CREATE FUNCTION check_user_project(uname text, project text) RETURNS text
    LANGUAGE plpgsql COST 1
    AS $_$
declare proj_id integer;
begin
proj_id:=0;
select id from projects where name=$2 into proj_id;
--RAISE NOTICE '%', proj_id;
if proj_id=0 OR proj_id IS NULL then
	return 'TR.noProject';
else
	select idx(project_ids,proj_id) from users where user_name=$1 INTO proj_id;
	--RAISE NOTICE '%', proj_id;
	if proj_id=0 then return 'TR.noPermission';
	elseif proj_id IS NULL then return 'TR.noUser';
	else return 'OK';
	end if;
end if;
end;
$_$;


ALTER FUNCTION public.check_user_project(uname text, project text) OWNER TO pguser;

--
-- TOC entry 2123 (class 0 OID 0)
-- Dependencies: 203
-- Name: FUNCTION check_user_project(uname text, project text); Type: COMMENT; Schema: public; Owner: pguser
--

COMMENT ON FUNCTION check_user_project(uname text, project text) IS 'IN uname, project --> validates project, user and user permissions on project';


--
-- TOC entry 204 (class 1255 OID 84091)
-- Name: get_project_data(text); Type: FUNCTION; Schema: public; Owner: pguser
--

CREATE FUNCTION get_project_data(project text) RETURNS TABLE(client_name text, client_display_name text, theme_name text, overview_layer json, base_layers json, extra_layers json, tables_onstart text[])
    LANGUAGE plpgsql COST 1
    AS $_$
declare base json;
declare overview json;
declare extra json;
begin
base:=null;
overview:=null;

SELECT json_agg(('new OpenLayers.Layer.'|| layers.type) || '(' || layers.definition || ');')
FROM projects,layers where layers.id = ANY(projects.base_layers_ids) AND base_layer=true and projects.name=$1 INTO base;

SELECT json_agg(('new OpenLayers.Layer.'|| layers.type) || '(' || layers.definition || ');')
FROM projects,layers where layers.id = ANY(projects.extra_layers_ids) AND base_layer=false and projects.name=$1 INTO extra;

SELECT json_agg(('new OpenLayers.Layer.'|| layers.type) || '(' || layers.definition || ');')
FROM projects,layers where layers.id = projects.overview_layer_id and projects.name=$1 INTO overview;


RETURN QUERY SELECT clients.name, clients.display_name, themes.name, overview,base,extra, projects.tables_onstart FROM projects,clients,themes WHERE clients.theme_id=themes.id AND projects.client_id = clients.id AND projects.name=$1;
end;
$_$;


ALTER FUNCTION public.get_project_data(project text) OWNER TO pguser;

--
-- TOC entry 2124 (class 0 OID 0)
-- Dependencies: 204
-- Name: FUNCTION get_project_data(project text); Type: COMMENT; Schema: public; Owner: pguser
--

COMMENT ON FUNCTION get_project_data(project text) IS 'IN project --> client, theme, baselayers, overview layer, extra layers and tables_onstart for project_name.';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 170 (class 1259 OID 84093)
-- Name: clients; Type: TABLE; Schema: public; Owner: pguser; Tablespace: 
--

CREATE TABLE clients (
    id integer NOT NULL,
    name text NOT NULL,
    display_name text,
    theme_id integer
);


ALTER TABLE public.clients OWNER TO pguser;

--
-- TOC entry 171 (class 1259 OID 84099)
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: pguser
--

CREATE SEQUENCE clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.clients_id_seq OWNER TO pguser;

--
-- TOC entry 2125 (class 0 OID 0)
-- Dependencies: 171
-- Name: clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pguser
--

ALTER SEQUENCE clients_id_seq OWNED BY clients.id;


--
-- TOC entry 172 (class 1259 OID 84101)
-- Name: layers; Type: TABLE; Schema: public; Owner: pguser; Tablespace: 
--

CREATE TABLE layers (
    id integer NOT NULL,
    name text NOT NULL,
    display_name text,
    type text NOT NULL,
    base_layer boolean NOT NULL,
    definition text NOT NULL
);


ALTER TABLE public.layers OWNER TO pguser;

--
-- TOC entry 173 (class 1259 OID 84107)
-- Name: layers_id_seq; Type: SEQUENCE; Schema: public; Owner: pguser
--

CREATE SEQUENCE layers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.layers_id_seq OWNER TO pguser;

--
-- TOC entry 2126 (class 0 OID 0)
-- Dependencies: 173
-- Name: layers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pguser
--

ALTER SEQUENCE layers_id_seq OWNED BY layers.id;


--
-- TOC entry 174 (class 1259 OID 84109)
-- Name: projects; Type: TABLE; Schema: public; Owner: pguser; Tablespace: 
--

CREATE TABLE projects (
    id integer NOT NULL,
    name text NOT NULL,
    overview_layer_id integer,
    base_layers_ids integer[],
    extra_layers_ids integer[],
    client_id integer,
    tables_onstart text[]
);


ALTER TABLE public.projects OWNER TO pguser;

--
-- TOC entry 175 (class 1259 OID 84115)
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: pguser
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_id_seq OWNER TO pguser;

--
-- TOC entry 2127 (class 0 OID 0)
-- Dependencies: 175
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pguser
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- TOC entry 176 (class 1259 OID 84117)
-- Name: themes; Type: TABLE; Schema: public; Owner: pguser; Tablespace: 
--

CREATE TABLE themes (
    id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.themes OWNER TO pguser;

--
-- TOC entry 177 (class 1259 OID 84123)
-- Name: themes_id_seq; Type: SEQUENCE; Schema: public; Owner: pguser
--

CREATE SEQUENCE themes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.themes_id_seq OWNER TO pguser;

--
-- TOC entry 2128 (class 0 OID 0)
-- Dependencies: 177
-- Name: themes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: pguser
--

ALTER SEQUENCE themes_id_seq OWNED BY themes.id;


--
-- TOC entry 178 (class 1259 OID 84125)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE users (
    user_id integer NOT NULL,
    user_name text,
    user_password_hash text,
    user_email text,
    display_name text,
    last_login timestamp with time zone,
    count_login integer DEFAULT 0,
    project_ids integer[]
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 179 (class 1259 OID 84132)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_user_id_seq OWNER TO postgres;

--
-- TOC entry 2129 (class 0 OID 0)
-- Dependencies: 179
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE users_user_id_seq OWNED BY users.user_id;


--
-- TOC entry 1968 (class 2604 OID 84134)
-- Name: id; Type: DEFAULT; Schema: public; Owner: pguser
--

ALTER TABLE ONLY clients ALTER COLUMN id SET DEFAULT nextval('clients_id_seq'::regclass);


--
-- TOC entry 1969 (class 2604 OID 84135)
-- Name: id; Type: DEFAULT; Schema: public; Owner: pguser
--

ALTER TABLE ONLY layers ALTER COLUMN id SET DEFAULT nextval('layers_id_seq'::regclass);


--
-- TOC entry 1970 (class 2604 OID 84136)
-- Name: id; Type: DEFAULT; Schema: public; Owner: pguser
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- TOC entry 1971 (class 2604 OID 84137)
-- Name: id; Type: DEFAULT; Schema: public; Owner: pguser
--

ALTER TABLE ONLY themes ALTER COLUMN id SET DEFAULT nextval('themes_id_seq'::regclass);


--
-- TOC entry 1973 (class 2604 OID 84138)
-- Name: user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN user_id SET DEFAULT nextval('users_user_id_seq'::regclass);


--
-- TOC entry 2106 (class 0 OID 84101)
-- Dependencies: 172
-- Data for Name: layers; Type: TABLE DATA; Schema: public; Owner: pguser
--

INSERT INTO layers VALUES (1, 'google_map', '', 'Google', true, '"Google "+TR.mapBasic,{type: google.maps.MapTypeId.MAP, numZoomLevels: 20, isBaseLayer: true}');
INSERT INTO layers VALUES (2, 'google_sat', '', 'Google', true, '"Google "+TR.mapSatellite,{type: google.maps.MapTypeId.SATELLITE, numZoomLevels: 20, isBaseLayer: true}');
INSERT INTO layers VALUES (3, 'mapquest_map', '', 'OSM', true, '"MapQuest-OSM "+TR.mapBasic, ["http://otile1.mqcdn.com/tiles/1.0.0/map/${z}/${x}/${y}.jpg","http://otile2.mqcdn.com/tiles/1.0.0/map/${z}/${x}/${y}.jpg","http://otile3.mqcdn.com/tiles/1.0.0/map/${z}/${x}/${y}.jpg","http://otile4.mqcdn.com/tiles/1.0.0/map/${z}/${x}/${y}.jpg"], {numZoomLevels: 19, attribution: "Data, imagery and map information provided by <a href=''http://www.mapquest.com/''  target=''_blank''>MapQuest</a>, <a href=''http://www.openstreetmap.org/'' target=''_blank''>Open Street Map</a> and contributors, <a href=''http://creativecommons.org/licenses/by-sa/2.0/'' target=''_blank''>CC-BY-SA</a>  <img src=''http://developer.mapquest.com/content/osm/mq_logo.png'' border=''0''>"}');


--
-- TOC entry 2131 (class 0 OID 0)
-- Dependencies: 173
-- Name: layers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pguser
--

SELECT pg_catalog.setval('layers_id_seq', 4, true);


--
-- TOC entry 2110 (class 0 OID 84117)
-- Dependencies: 176
-- Data for Name: themes; Type: TABLE DATA; Schema: public; Owner: pguser
--

INSERT INTO themes VALUES (1, 'xtheme-blue.css');
INSERT INTO themes VALUES (2, 'xtheme-gray.css');


--
-- TOC entry 2133 (class 0 OID 0)
-- Dependencies: 177
-- Name: themes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: pguser
--

SELECT pg_catalog.setval('themes_id_seq', 1, false);



ALTER TABLE ONLY clients
    ADD CONSTRAINT clients_name_key UNIQUE (name);


--
-- TOC entry 1977 (class 2606 OID 84142)
-- Name: clients_pkey; Type: CONSTRAINT; Schema: public; Owner: pguser; Tablespace: 
--

ALTER TABLE ONLY clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- TOC entry 1979 (class 2606 OID 84144)
-- Name: layers_layer_name_key; Type: CONSTRAINT; Schema: public; Owner: pguser; Tablespace: 
--

ALTER TABLE ONLY layers
    ADD CONSTRAINT layers_layer_name_key UNIQUE (name);


--
-- TOC entry 1981 (class 2606 OID 84146)
-- Name: layers_pkey; Type: CONSTRAINT; Schema: public; Owner: pguser; Tablespace: 
--

ALTER TABLE ONLY layers
    ADD CONSTRAINT layers_pkey PRIMARY KEY (id);


--
-- TOC entry 1983 (class 2606 OID 84148)
-- Name: projects_name_key; Type: CONSTRAINT; Schema: public; Owner: pguser; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_name_key UNIQUE (name);


--
-- TOC entry 1985 (class 2606 OID 84150)
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: pguser; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- TOC entry 1987 (class 2606 OID 84152)
-- Name: themes_name_key; Type: CONSTRAINT; Schema: public; Owner: pguser; Tablespace: 
--

ALTER TABLE ONLY themes
    ADD CONSTRAINT themes_name_key UNIQUE (name);


--
-- TOC entry 1989 (class 2606 OID 84154)
-- Name: themes_pkey; Type: CONSTRAINT; Schema: public; Owner: pguser; Tablespace: 
--

ALTER TABLE ONLY themes
    ADD CONSTRAINT themes_pkey PRIMARY KEY (id);


--
-- TOC entry 1991 (class 2606 OID 84156)
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 1993 (class 2606 OID 84158)
-- Name: users_user_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_user_name_key UNIQUE (user_name);


--
-- TOC entry 1994 (class 2606 OID 84159)
-- Name: clients_theme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pguser
--

ALTER TABLE ONLY clients
    ADD CONSTRAINT clients_theme_id_fkey FOREIGN KEY (theme_id) REFERENCES themes(id);


--
-- TOC entry 1995 (class 2606 OID 84164)
-- Name: projects_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pguser
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id);


--
-- TOC entry 1996 (class 2606 OID 84169)
-- Name: projects_overview_layer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pguser
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_overview_layer_id_fkey FOREIGN KEY (overview_layer_id) REFERENCES layers(id);


--
-- TOC entry 2120 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;

