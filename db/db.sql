--
-- PostgreSQL database dump
--

-- Dumped from database version 10.13 (Ubuntu 10.13-1.pgdg18.04+1)
-- Dumped by pg_dump version 12.3 (Ubuntu 12.3-1.pgdg18.04+1)

-- Started on 2020-07-08 08:58:27 BST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 148541)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 4437 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 2 (class 3079 OID 148546)
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- TOC entry 4438 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- TOC entry 3 (class 3079 OID 148553)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 4439 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- TOC entry 4 (class 3079 OID 150052)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 4440 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

--
-- TOC entry 215 (class 1259 OID 150063)
-- Name: contributions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contributions (
    contribution_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    geonameid integer NOT NULL,
    path character varying NOT NULL,
    user_agent character varying,
    points_geom public.geometry,
    points_time timestamp with time zone[],
    points_size integer DEFAULT 0 NOT NULL,
    points_hash character(32) NOT NULL,
    started_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    distance integer,
    duration integer
);


ALTER TABLE public.contributions OWNER TO postgres;

--
-- TOC entry 1431 (class 1255 OID 150073)
-- Name: create_contribution_at(integer, uuid, character varying, character varying, public.geometry, timestamp without time zone[], timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_contribution_at(geonameid integer, user_id uuid, user_agent character varying, path character varying, in_points_geom public.geometry, in_points_time timestamp without time zone[], now timestamp with time zone DEFAULT now()) RETURNS public.contributions
    LANGUAGE plpgsql
    AS $$
  DECLARE
    contrib contributions;
    in_duration numeric;
    in_distance numeric;
    in_points_hash char(32);
  BEGIN
    -- 0. validate the points_geom and points_time
    IF ST_NumPoints(in_points_geom) < 2 THEN
      RAISE EXCEPTION 'geometry must have at least 2 points';
    END IF;
    IF ST_NumPoints(in_points_geom) <> array_length(in_points_time, 1) THEN
      RAISE EXCEPTION 'geometry and times does not match';
    END IF;

    -- calculate the distance, duration and hash
    SELECT
      round(ST_Length(in_points_geom::geography, FALSE)),
      EXTRACT(EPOCH FROM in_points_time[array_length(in_points_time, 1)] - in_points_time[1]),
      md5(concat(in_points_geom, in_points_time))
    INTO in_distance, in_duration, in_points_hash;

    -- validate the speed
    IF (in_distance / 1000.0) / (in_duration / 3600.0) > 70.0 THEN
      RAISE EXCEPTION 'too fast. ignoring contribution';
    END IF;

    -- 1. insert into contribution table
    --    and ignore if it already exists (mainly for when loading
    --    contributions from external sources like moves)
    BEGIN
      INSERT INTO contributions
      (geonameid, user_id, user_agent, path, points_geom, points_time, points_hash, points_size, distance, duration, started_at, created_at, updated_at)
      VALUES
      (geonameid, user_id, user_agent, path, in_points_geom, in_points_time, in_points_hash, array_length(in_points_time, 1), in_distance, in_duration, in_points_time[1], now, now)
      RETURNING * INTO STRICT contrib;
    EXCEPTION
      WHEN unique_violation THEN
        SELECT * INTO contrib FROM contributions WHERE points_hash = in_points_hash LIMIT 1;
        RETURN contrib;
    END;

    -- 2. update goals globally, regionally and locally
    PERFORM update_goal_at(NULL, NULL, now); -- global
    PERFORM update_goal_at(geonameid, NULL, now); -- regional
    PERFORM update_goal_at(NULL, user_id, now); -- local

    RETURN contrib;
  END;
  $$;


ALTER FUNCTION public.create_contribution_at(geonameid integer, user_id uuid, user_agent character varying, path character varying, in_points_geom public.geometry, in_points_time timestamp without time zone[], now timestamp with time zone) OWNER TO postgres;

--
-- TOC entry 1432 (class 1255 OID 150074)
-- Name: create_nearest_contribution(uuid, character varying, character varying, public.geometry, timestamp without time zone[], timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_nearest_contribution(user_id uuid, user_agent character varying, path character varying, in_points_geom public.geometry, in_points_time timestamp without time zone[], now timestamp with time zone DEFAULT now()) RETURNS public.contributions
    LANGUAGE plpgsql
    AS $$
DECLARE
  contrib contributions;
  geonameid integer;
BEGIN

  -- 1. Find the nearest place
  -- 1.1. start by checking intersections
  SELECT split_part(qs_gn_id, ',', 1)::integer INTO geonameid
  FROM localities as q
  WHERE wkb_geometry ~ in_points_geom
  AND wkb_geometry::geography && in_points_geom::geography
  ORDER BY ST_Distance(wkb_geometry::geography, ST_Centroid(in_points_geom)::geography) ASC
  LIMIT 1;

  -- 1.2. fallback to find near a point
  IF geonameid IS NULL THEN
    SELECT g.geonameid INTO geonameid
    FROM geonames as g
    WHERE fcode IN ('PPLA', 'PPLA2', 'PPLC')
    ORDER BY geom <-> ST_Centroid(in_points_geom) ASC
    LIMIT 1;
  END IF;

  -- 2. Create contribution using the original function
  SELECT * INTO contrib FROM create_contribution_at(geonameid, user_id, user_agent, path, in_points_geom, in_points_time, now);

  RETURN contrib;
END;
$$;


ALTER FUNCTION public.create_nearest_contribution(user_id uuid, user_agent character varying, path character varying, in_points_geom public.geometry, in_points_time timestamp without time zone[], now timestamp with time zone) OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 150075)
-- Name: geonames; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.geonames (
    geonameid integer NOT NULL,
    name character varying(200),
    asciiname character varying(200),
    latitude double precision,
    longitude double precision,
    fclass character(1),
    fcode character varying(10),
    country character varying(2),
    cc2 character varying(60),
    admin1 character varying(20),
    admin2 character varying(80),
    admin3 character varying(20),
    admin4 character varying(20),
    population bigint,
    elevation integer,
    gtopo30 integer,
    timezone character varying(40),
    moddate date,
    geom public.geometry(Point,4326),
    key_parts character varying[]
);


ALTER TABLE public.geonames OWNER TO postgres;

--
-- TOC entry 1433 (class 1255 OID 150081)
-- Name: find_nearest_place(public.geometry); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_nearest_place(in_points_geom public.geometry) RETURNS public.geonames
    LANGUAGE plpgsql
    AS $$
DECLARE
  tmp_geonameid integer;
  geoname geonames;
BEGIN
  -- 1. Find the nearest place
  -- 1.1. start by checking intersections
  SELECT split_part(qs_gn_id, ',', 1)::integer INTO tmp_geonameid
  FROM localities as q
  WHERE wkb_geometry ~ in_points_geom
  AND wkb_geometry::geography && in_points_geom::geography
  ORDER BY ST_Distance(wkb_geometry::geography, ST_Centroid(in_points_geom)::geography) ASC
  LIMIT 1;

  -- 1.1. Then map to a geoname row
  IF tmp_geonameid IS NOT NULL THEN
    RAISE NOTICE 'tmp_geonameid found: % trying to map to geonames', tmp_geonameid;
    SELECT * INTO geoname
    FROM geonames as g
    WHERE g.geonameid = tmp_geonameid
    LIMIT 1;
  END IF;

  -- 1.2. but also fallback to find near a point in case no row matched
  IF tmp_geonameid IS NULL OR geoname IS NULL THEN
    RAISE NOTICE 'no overlapping geonameid found. trying by distance to geonames';
    SELECT * INTO geoname
    FROM geonames as g
    WHERE fcode IN ('PPLA', 'PPLA2', 'PPLC')
    ORDER BY geom <-> ST_Centroid(in_points_geom) ASC
    LIMIT 1;
  END IF;

  RETURN geoname;
END;
$$;


ALTER FUNCTION public.find_nearest_place(in_points_geom public.geometry) OWNER TO postgres;

--
-- TOC entry 1434 (class 1255 OID 150082)
-- Name: nice_round(numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.nice_round(i numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
  CASE
    WHEN i <= 10 THEN
      RETURN round(i);
    WHEN i <= 100 THEN
      RETURN round(i, -1);
    ELSE
      RETURN round_to(i, (pow(10, floor(log(i)))/2)::numeric);
  END CASE;
END;
$$;


ALTER FUNCTION public.nice_round(i numeric) OWNER TO postgres;

--
-- TOC entry 1435 (class 1255 OID 150083)
-- Name: parameterize(character varying[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.parameterize(arr character varying[]) RETURNS character varying[]
    LANGUAGE plpgsql
    AS $$
DECLARE
  ret varchar[];
BEGIN
  FOR I IN array_lower(arr, 1)..array_upper(arr, 1) LOOP
    ret[I] := parameterize(arr[I]);
  END LOOP;
  RETURN ret;
END;
$$;


ALTER FUNCTION public.parameterize(arr character varying[]) OWNER TO postgres;

--
-- TOC entry 1436 (class 1255 OID 150084)
-- Name: parameterize(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.parameterize(str character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN trim(both '-' from regexp_replace(lower(to_ascii(str, 'latin1')), '[^a-z0-9\-\/]+', '-', 'g'));
END;
$$;


ALTER FUNCTION public.parameterize(str character varying) OWNER TO postgres;

--
-- TOC entry 1437 (class 1255 OID 150085)
-- Name: round_to(numeric, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.round_to(num numeric, step integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN floor(num / step + .5) * step;
END;
$$;


ALTER FUNCTION public.round_to(num numeric, step integer) OWNER TO postgres;

--
-- TOC entry 1438 (class 1255 OID 150086)
-- Name: round_to(numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.round_to(num numeric, step numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN floor(num / step + .5) * step;
END;
$$;


ALTER FUNCTION public.round_to(num numeric, step numeric) OWNER TO postgres;

--
-- TOC entry 1439 (class 1255 OID 150087)
-- Name: update_goal(integer, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_goal(in_geonameid integer, in_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  curr_goal bigint default 0;
  curr_dist bigint default 0;
  prev_dist real;
  prev_time real;
  next_goal numeric default 1000;
  duration int default 604800; -- 1w in seconds
BEGIN
  -- get the current goal
  CASE
    WHEN in_geonameid IS NOT NULL THEN
      SELECT distance INTO curr_goal
      FROM goals
      WHERE geonameid = in_geonameid
      AND reached_at IS NULL
      ORDER BY created_at DESC
      LIMIT 1;
    WHEN in_user_id IS NOT NULL THEN
      SELECT distance INTO curr_goal
      FROM goals
      WHERE user_id = in_user_id
      AND reached_at IS NULL
      ORDER BY created_at DESC
      LIMIT 1;
    ELSE
      SELECT distance INTO curr_goal
      FROM goals
      WHERE reached_at IS NULL
      ORDER BY created_at DESC
      LIMIT 1;
  END CASE;

  -- no previous goal. create it first.
  IF NOT FOUND THEN
    INSERT INTO goals (distance, duration, geonameid, user_id)
    VALUES (next_goal, duration, in_geonameid, in_user_id)
    RETURNING distance INTO curr_goal;
  END IF;

  -- get the current distance
  CASE
    WHEN in_geonameid IS NOT NULL THEN
      SELECT sum(distance) INTO curr_dist
      FROM contributions
      WHERE geonameid = in_geonameid;
    WHEN in_user_id IS NOT NULL THEN
      SELECT sum(distance) INTO curr_dist
      FROM contributions
      WHERE user_id = in_user_id;
    ELSE
      SELECT sum(distance) INTO curr_dist
      FROM contributions;
  END CASE;

  -- reached goal?
  IF curr_dist >= curr_goal THEN
    -- mark the 'current' goal as 'reached'
    CASE
      WHEN in_geonameid IS NOT NULL THEN
        UPDATE goals SET reached_at = now()
        WHERE reached_at IS NULL
        AND geonameid = in_geonameid
        AND user_id IS NULL;
      WHEN in_user_id IS NOT NULL THEN
        UPDATE goals SET reached_at = now()
        WHERE reached_at IS NULL
        AND user_id = in_user_id
        AND geonameid IS NULL;
      ELSE
        UPDATE goals SET reached_at = now()
        WHERE reached_at IS NULL
        AND user_id IS NULL
        AND geonameid IS NULL;
    END CASE;

    -- calculate the next goal based on the time it took to reach previous goals
    CASE
      WHEN in_geonameid IS NOT NULL THEN
        SELECT avg(distance),
               avg(EXTRACT(EPOCH FROM reached_at - created_at))
               INTO prev_dist, prev_time
        FROM goals
        WHERE reached_at IS NOT NULL
        AND geonameid = in_geonameid
        AND user_id IS NULL
        LIMIT 3;
      WHEN in_user_id IS NOT NULL THEN
        SELECT avg(distance),
               avg(EXTRACT(EPOCH FROM reached_at - created_at))
               INTO prev_dist, prev_time
        FROM goals
        WHERE reached_at IS NOT NULL
        AND geonameid IS NULL
        AND user_id = in_user_id
        LIMIT 3;
      ELSE
        SELECT avg(distance),
               avg(EXTRACT(EPOCH FROM reached_at - created_at))
               INTO prev_dist, prev_time
        FROM goals
        WHERE reached_at IS NOT NULL
        AND geonameid IS NULL
        AND user_id IS NULL
        LIMIT 3;
    END CASE;

    -- minimum time step is 1 hour
    SELECT GREATEST(prev_time, 3600) INTO prev_time;

    next_goal = nice_round((prev_dist / prev_time * duration)::numeric);

    RAISE NOTICE 'calculating next goal using % / % * % = ~%', prev_dist, prev_time, duration, next_goal;

    -- finally create the new goal
    INSERT INTO goals (distance, duration, geonameid, user_id)
    VALUES (next_goal, duration, in_geonameid, in_user_id);
  END IF;
END;
$$;


ALTER FUNCTION public.update_goal(in_geonameid integer, in_user_id uuid) OWNER TO postgres;

--
-- TOC entry 1440 (class 1255 OID 150088)
-- Name: update_goal_at(integer, uuid, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_goal_at(in_geonameid integer, in_user_id uuid, now timestamp with time zone DEFAULT now()) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  curr_goal bigint default 0;
  curr_dist bigint default 0;
  prev_dist real;
  prev_time real;
  next_goal numeric default 1000;
  duration int default 604800; -- 1w in seconds
BEGIN
  LOCK TABLE goals IN SHARE ROW EXCLUSIVE MODE;

  -- get the current goal
  SELECT distance INTO curr_goal
  FROM goals
  WHERE reached_at IS NULL
  AND geonameid IS NOT DISTINCT FROM in_geonameid
  AND user_id IS NOT DISTINCT FROM in_user_id
  ORDER BY created_at DESC
  LIMIT 1;

  -- no previous goal. create it first.
  -- not using `now` to make it easier to test
  IF NOT FOUND THEN
    INSERT INTO goals (distance, duration, geonameid, user_id)
    VALUES (next_goal, duration, in_geonameid, in_user_id)
    RETURNING distance INTO curr_goal;
  END IF;

  -- get the current distance
  CASE
    WHEN in_geonameid IS NOT NULL THEN
      SELECT sum(distance) INTO curr_dist
      FROM contributions
      WHERE geonameid = in_geonameid;
    WHEN in_user_id IS NOT NULL THEN
      SELECT sum(distance) INTO curr_dist
      FROM contributions
      WHERE user_id = in_user_id;
    ELSE
      SELECT sum(distance) INTO curr_dist
      FROM contributions;
  END CASE;

  -- reached goal?
  IF curr_dist >= curr_goal THEN
    -- mark the 'current' goal as 'reached'
    UPDATE goals SET reached_at = now
    WHERE reached_at IS NULL
    AND geonameid IS NOT DISTINCT FROM in_geonameid
    AND user_id IS NOT DISTINCT FROM in_user_id;


    -- calculate the next goal based on the time it took to reach previous goals
    SELECT coalesce(avg(distance), 0),
           coalesce(avg(EXTRACT(EPOCH FROM reached_at - created_at)), 0)
           INTO prev_dist, prev_time
    FROM (
      SELECT *
      FROM goals
      WHERE reached_at IS NOT NULL
      AND geonameid IS NOT DISTINCT FROM in_geonameid
      AND user_id IS NOT DISTINCT FROM in_user_id
      ORDER BY created_at
      DESC LIMIT 3
    ) as g;

    -- minimum time step is 24 hours
    -- 1000/(1*60*60)*(7*24*60*60) = 167 000 (1km in 1hr = maximum 'jump')
    -- 1000/(24*60*60)*(7*24*60*60) = 7 000 (1km in 1d = maximum 'jump')
    SELECT GREATEST(prev_time, 24*60*60) INTO prev_time;

    RAISE LOG 'calculating next goal using % / % * %', prev_dist, prev_time, duration;

    next_goal = nice_round((prev_dist / prev_time * duration)::numeric);

    RAISE LOG ' = ~%', next_goal;

    -- finally create the new goal
    INSERT INTO goals (distance, duration, geonameid, user_id, created_at)
    VALUES (next_goal, duration, in_geonameid, in_user_id, now);
  END IF;
END;
$$;


ALTER FUNCTION public.update_goal_at(in_geonameid integer, in_user_id uuid, now timestamp with time zone) OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 150089)
-- Name: admincodes1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admincodes1 (
    code character(15),
    name character varying,
    nameascii character varying,
    geonameid integer
);


ALTER TABLE public.admincodes1 OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 150095)
-- Name: admincodes2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admincodes2 (
    code character varying,
    name character varying,
    nameascii character varying,
    geonameid integer
);


ALTER TABLE public.admincodes2 OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 150101)
-- Name: alternatenames; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alternatenames (
    alternatename_id integer NOT NULL,
    geonameid integer,
    iso_639_1 character varying(7),
    alternatename character varying(300),
    ispreferredname boolean,
    isshortname boolean,
    iscolloquial boolean,
    ishistoric boolean
);


ALTER TABLE public.alternatenames OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 150104)
-- Name: continents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.continents (
    code character(2),
    name character varying(20),
    geonameid integer
);


ALTER TABLE public.continents OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 150107)
-- Name: countryinfo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.countryinfo (
    iso_alpha2 character(2) NOT NULL,
    iso_alpha3 character(3),
    iso_numeric integer,
    fips_code character varying(3),
    country character varying(200),
    capital character varying(200),
    areainsqkm double precision,
    population integer,
    continent character(2),
    tld character(10),
    currency_code character(3),
    currency_name character(15),
    phone character varying(20),
    postal character varying(60),
    postalregex character varying(200),
    languages character varying(200),
    geonameid integer,
    neighbours character varying(50),
    equivalent_fips_code character varying(3)
);


ALTER TABLE public.countryinfo OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 150113)
-- Name: credentials; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.credentials (
    credential_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    provider character varying NOT NULL,
    provider_id character varying NOT NULL,
    access_token character varying,
    refresh_token character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    expired_at timestamp with time zone,
    expires_at timestamp with time zone,
    meta json DEFAULT '{}'::json
);


ALTER TABLE public.credentials OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 150123)
-- Name: goals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.goals (
    goal_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    distance bigint DEFAULT 0 NOT NULL,
    duration integer DEFAULT 604800 NOT NULL,
    geonameid integer,
    user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    reached_at timestamp with time zone
);


ALTER TABLE public.goals OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 150131)
-- Name: languagecodes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.languagecodes (
    iso_639_3 character(4),
    iso_639_2 character varying(50),
    iso_639_1 character varying(50),
    language_name character varying(200)
);


ALTER TABLE public.languagecodes OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 150134)
-- Name: localities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.localities (
    ogc_fid integer NOT NULL,
    wkb_geometry public.geometry(MultiPolygon,4326),
    qs_a1_alt character varying(200),
    qs_a2r character varying(200),
    qs_level character varying(30),
    qs_gn_id character varying(254),
    qs_iso_cc character varying(2),
    qs_la_lc character varying(200),
    qs_id numeric(10,0),
    qs_a1 character varying(200),
    qs_a0 character varying(200),
    qs_a2 character varying(200),
    qs_a2_alt character varying(200),
    qs_a2_lc character varying(200),
    qs_scale numeric(10,0),
    qs_pop numeric(10,0),
    qs_a0_lc character varying(200),
    qs_a1r_lc character varying(200),
    qs_a2r_lc character varying(200),
    qs_loc_alt character varying(200),
    qs_adm0 character varying(200),
    qs_adm0_a3 character varying(3),
    qs_source character varying(200),
    qs_la character varying(200),
    qs_la_alt character varying(200),
    qs_a1_lc character varying(200),
    qs_type character varying(200),
    qs_a1r_alt character varying(200),
    qs_loc_lc character varying(200),
    gs_gn_id character varying(255),
    qs_loc character varying(200),
    qs_a2r_alt character varying(200),
    qs_woe_id numeric(10,0),
    qs_a1r character varying(200)
);


ALTER TABLE public.localities OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 150140)
-- Name: localities_ogc_fid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.localities_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.localities_ogc_fid_seq OWNER TO postgres;

--
-- TOC entry 4441 (class 0 OID 0)
-- Dependencies: 226
-- Name: localities_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.localities_ogc_fid_seq OWNED BY public.localities.ogc_fid;


--
-- TOC entry 227 (class 1259 OID 150142)
-- Name: migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    run_on timestamp without time zone NOT NULL
);


ALTER TABLE public.migrations OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 150145)
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.migrations_id_seq OWNER TO postgres;

--
-- TOC entry 4442 (class 0 OID 0)
-- Dependencies: 228
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- TOC entry 229 (class 1259 OID 150147)
-- Name: timezones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.timezones (
    timezone_id character(2),
    timezone_name character varying(200),
    gmt_offset numeric(3,1),
    dst_offset numeric(3,1),
    raw_offset numeric(3,1)
);


ALTER TABLE public.timezones OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 150150)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    password character varying(60) NOT NULL,
    created_at timestamp without time zone DEFAULT '2015-02-12 17:03:36.204967'::timestamp without time zone,
    updated_at timestamp without time zone DEFAULT '2015-02-12 17:03:36.204967'::timestamp without time zone,
    device_id character varying
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 4252 (class 2604 OID 150159)
-- Name: localities ogc_fid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localities ALTER COLUMN ogc_fid SET DEFAULT nextval('public.localities_ogc_fid_seq'::regclass);


--
-- TOC entry 4253 (class 2604 OID 150160)
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- TOC entry 4261 (class 2606 OID 1362516)
-- Name: contributions contributions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contributions
    ADD CONSTRAINT contributions_pkey PRIMARY KEY (contribution_id);


--
-- TOC entry 4286 (class 2606 OID 1362518)
-- Name: credentials credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_pkey PRIMARY KEY (credential_id);


--
-- TOC entry 4289 (class 2606 OID 1362520)
-- Name: goals goals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.goals
    ADD CONSTRAINT goals_pkey PRIMARY KEY (goal_id);


--
-- TOC entry 4292 (class 2606 OID 1362522)
-- Name: localities localities_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localities
    ADD CONSTRAINT localities_pk PRIMARY KEY (ogc_fid);


--
-- TOC entry 4295 (class 2606 OID 1362524)
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 4281 (class 2606 OID 1362526)
-- Name: alternatenames pk_alternatenameid; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alternatenames
    ADD CONSTRAINT pk_alternatenameid PRIMARY KEY (alternatename_id);


--
-- TOC entry 4278 (class 2606 OID 1362528)
-- Name: geonames pk_geonameid; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.geonames
    ADD CONSTRAINT pk_geonameid PRIMARY KEY (geonameid);


--
-- TOC entry 4284 (class 2606 OID 1362530)
-- Name: countryinfo pk_iso_alpha2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countryinfo
    ADD CONSTRAINT pk_iso_alpha2 PRIMARY KEY (iso_alpha2);


--
-- TOC entry 4297 (class 2606 OID 1362532)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4259 (class 1259 OID 1362619)
-- Name: contributions_gix; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX contributions_gix ON public.contributions USING gist (points_geom);


--
-- TOC entry 4279 (class 1259 OID 1362533)
-- Name: idx_alternatename_geonameid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alternatename_geonameid ON public.alternatenames USING hash (geonameid);


--
-- TOC entry 4262 (class 1259 OID 1362534)
-- Name: idx_contributions_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contributions_created_at ON public.contributions USING btree (created_at);


--
-- TOC entry 4263 (class 1259 OID 1362535)
-- Name: idx_contributions_daily; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contributions_daily ON public.contributions USING btree (date_trunc('day'::text, timezone('UTC'::text, started_at)));


--
-- TOC entry 4264 (class 1259 OID 1362536)
-- Name: idx_contributions_distance; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contributions_distance ON public.contributions USING btree (distance);


--
-- TOC entry 4265 (class 1259 OID 1362537)
-- Name: idx_contributions_duration; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contributions_duration ON public.contributions USING btree (duration);


--
-- TOC entry 4266 (class 1259 OID 1362538)
-- Name: idx_contributions_geonameid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contributions_geonameid ON public.contributions USING hash (geonameid);


--
-- TOC entry 4267 (class 1259 OID 1362539)
-- Name: idx_contributions_monthly; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contributions_monthly ON public.contributions USING btree (date_trunc('month'::text, timezone('UTC'::text, started_at)));


--
-- TOC entry 4268 (class 1259 OID 1362540)
-- Name: idx_contributions_started_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contributions_started_at ON public.contributions USING btree (started_at);


--
-- TOC entry 4269 (class 1259 OID 1362541)
-- Name: idx_contributions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contributions_user_id ON public.contributions USING btree (user_id);


--
-- TOC entry 4270 (class 1259 OID 1362542)
-- Name: idx_contributions_weekly; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_contributions_weekly ON public.contributions USING btree (date_trunc('week'::text, timezone('UTC'::text, started_at)));


--
-- TOC entry 4282 (class 1259 OID 1362543)
-- Name: idx_countryinfo_geonameid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_countryinfo_geonameid ON public.countryinfo USING hash (geonameid);


--
-- TOC entry 4272 (class 1259 OID 1362544)
-- Name: idx_geonames_geom; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_geonames_geom ON public.geonames USING gist (geom);


--
-- TOC entry 4273 (class 1259 OID 1362545)
-- Name: idx_geonames_key_parts_1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_geonames_key_parts_1 ON public.geonames USING btree ((key_parts[1]));


--
-- TOC entry 4274 (class 1259 OID 1362546)
-- Name: idx_geonames_key_parts_1_2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_geonames_key_parts_1_2 ON public.geonames USING btree ((key_parts[1:2]));


--
-- TOC entry 4275 (class 1259 OID 1362547)
-- Name: idx_geonames_key_parts_1_3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_geonames_key_parts_1_3 ON public.geonames USING btree ((key_parts[1:3]));


--
-- TOC entry 4276 (class 1259 OID 1362548)
-- Name: idx_geonames_key_parts_1_4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_geonames_key_parts_1_4 ON public.geonames USING btree ((key_parts[1:4]));


--
-- TOC entry 4271 (class 1259 OID 1362549)
-- Name: idx_unique_contributions; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_contributions ON public.contributions USING btree (points_hash);


--
-- TOC entry 4287 (class 1259 OID 1362569)
-- Name: idx_unique_credentials; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_credentials ON public.credentials USING btree (provider, provider_id, COALESCE(expired_at, '1900-01-01 00:00:00+00'::timestamp with time zone));


--
-- TOC entry 4290 (class 1259 OID 1362570)
-- Name: idx_unique_goals; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unique_goals ON public.goals USING btree (COALESCE(geonameid, '-1'::integer), COALESCE(user_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(reached_at, '1900-01-01 00:00:00+00'::timestamp with time zone));


--
-- TOC entry 4293 (class 1259 OID 1362571)
-- Name: localities_wkb_geometry_geom_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX localities_wkb_geometry_geom_idx ON public.localities USING gist (wkb_geometry);


--
-- TOC entry 4298 (class 2606 OID 1362575)
-- Name: contributions contributions_geonameid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contributions
    ADD CONSTRAINT contributions_geonameid_fkey FOREIGN KEY (geonameid) REFERENCES public.geonames(geonameid);


--
-- TOC entry 4299 (class 2606 OID 1362580)
-- Name: contributions contributions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contributions
    ADD CONSTRAINT contributions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 4301 (class 2606 OID 1362585)
-- Name: credentials credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 4300 (class 2606 OID 1362590)
-- Name: alternatenames fk_geonameid; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alternatenames
    ADD CONSTRAINT fk_geonameid FOREIGN KEY (geonameid) REFERENCES public.geonames(geonameid);


--
-- TOC entry 4302 (class 2606 OID 1362595)
-- Name: goals goals_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.goals
    ADD CONSTRAINT goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


-- Completed on 2020-07-08 08:58:29 BST

--
-- PostgreSQL database dump complete
--

