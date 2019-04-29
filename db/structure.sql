--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: suggestions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA suggestions;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;


--
-- Name: EXTENSION intarray; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

--
-- Name: anyarray_concat_uniq(anyarray, anyarray); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION anyarray_concat_uniq(with_array anyarray, concat_array anyarray) RETURNS anyarray
    LANGUAGE plpgsql
    AS $$
  DECLARE
    -- The variable used to track iteration over "with_array".
    loop_offset integer;

    -- The array to be returned by this function.
    return_array with_array%TYPE;
  BEGIN
    IF with_array IS NULL THEN
      RETURN concat_array;
    ELSEIF concat_array IS NULL THEN
      RETURN with_array;
    END IF;

    -- Add all items in "with_array" to "return_array".
    return_array = with_array;

    -- Iterate over each element in "concat_array".
    FOR loop_offset IN ARRAY_LOWER(concat_array, 1)..ARRAY_UPPER(concat_array, 1) LOOP
      IF NOT concat_array[loop_offset] = ANY(return_array) THEN
        return_array = ARRAY_APPEND(return_array, concat_array[loop_offset]);
      END IF;
    END LOOP;

    RETURN return_array;
  END;
$$;


--
-- Name: anyarray_concat_uniq(anyarray, anynonarray); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION anyarray_concat_uniq(with_array anyarray, concat_element anynonarray) RETURNS anyarray
    LANGUAGE plpgsql
    AS $$
  BEGIN
    RETURN ANYARRAY_CONCAT_UNIQ(with_array, ARRAY[concat_element]);
  END;
$$;


--
-- Name: anyarray_uniq(anyarray); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION anyarray_uniq(with_array anyarray) RETURNS anyarray
    LANGUAGE plpgsql
    AS $$
DECLARE
-- The variable used to track iteration over "with_array".
loop_offset integer;

-- The array to be returned by this function.
return_array with_array%TYPE := '{}';
BEGIN
  IF with_array IS NULL THEN
    return NULL;
  END IF;

  -- Iterate over each element in
  -- "concat_array".
  FOR loop_offset IN ARRAY_LOWER(with_array, 1)..ARRAY_UPPER(with_array, 1) LOOP
    IF NOT with_array[loop_offset] = ANY(return_array) THEN
      return_array = ARRAY_APPEND(return_array, with_array[loop_offset]);
    END IF;
  END LOOP;

  RETURN return_array;
END;
$$;


--
-- Name: counter_cache(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION counter_cache() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
          DECLARE
            table_name text := quote_ident(TG_ARGV[0]);
            table_fk_name text := quote_ident(TG_ARGV[1]);
            fk_name text := quote_ident(TG_ARGV[2]);
            counter_name text := quote_ident(TG_ARGV[3]);
            fk_changed boolean := false;
            fk_value integer;
            record record;
          BEGIN
            IF TG_OP = 'UPDATE' THEN
              record := NEW;
              EXECUTE 'SELECT ($1).' || fk_name || ' != ' || '($2).' || fk_name
              INTO fk_changed
              USING OLD, NEW;
            END IF;

            IF TG_OP = 'DELETE' OR fk_changed THEN
              record := OLD;
              EXECUTE 'SELECT ($1).' || fk_name INTO fk_value USING record;
              PERFORM increment_counter(table_name, table_fk_name, counter_name, fk_value, -1);
            END IF;

            IF TG_OP = 'INSERT' OR fk_changed THEN
              record := NEW;
              EXECUTE 'SELECT ($1).' || fk_name INTO fk_value USING record;
              PERFORM increment_counter(table_name, table_fk_name, counter_name, fk_value, 1);
            END IF;

            RETURN record;
          END;
        $_$;


--
-- Name: counter_cache_text(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION counter_cache_text() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
          DECLARE
            table_name text := quote_ident(TG_ARGV[0]);
            table_fk_name text := quote_ident(TG_ARGV[1]);
            fk_name text := quote_ident(TG_ARGV[2]);
            counter_name text := quote_ident(TG_ARGV[3]);
            fk_changed boolean := false;
            fk_value text;
            record record;
          BEGIN
            IF TG_OP = 'UPDATE' THEN
              record := NEW;
              EXECUTE 'SELECT ($1).' || fk_name || ' != ' || '($2).' || fk_name
              INTO fk_changed
              USING OLD, NEW;
            END IF;

            IF TG_OP = 'DELETE' OR fk_changed THEN
              record := OLD;
              EXECUTE 'SELECT ($1).' || fk_name INTO fk_value USING record;
              PERFORM increment_counter_text(table_name, table_fk_name, counter_name, fk_value, -1);
            END IF;

            IF TG_OP = 'INSERT' OR fk_changed THEN
              record := NEW;
              EXECUTE 'SELECT ($1).' || fk_name INTO fk_value USING record;
              PERFORM increment_counter_text(table_name, table_fk_name, counter_name, fk_value, 1);
            END IF;

            RETURN record;
          END;
        $_$;


--
-- Name: increment_counter(text, text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION increment_counter(table_name text, table_column_name text, column_name text, id integer, step integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
          DECLARE
            table_name text := quote_ident(table_name);
            table_column_name text := quote_ident(table_column_name);
            column_name text := quote_ident(column_name);

            conditions text := ' WHERE ' || table_column_name || ' = $1';
            updates text := column_name || '=' || column_name || '+' || step;
          BEGIN
            EXECUTE 'UPDATE ' || table_name || ' SET ' || updates || conditions
            USING id;
          END;

        $_$;


--
-- Name: increment_counter_text(text, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION increment_counter_text(table_name text, table_column_name text, column_name text, id text, step integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$
          DECLARE
            table_name text := quote_ident(table_name);
            table_column_name text := quote_ident(table_column_name);
            column_name text := quote_ident(column_name);

            conditions text := ' WHERE ' || table_column_name || ' = $1';
            updates text := column_name || '=' || column_name || '+' || step;
          BEGIN
            EXECUTE 'UPDATE ' || table_name || ' SET ' || updates || conditions
            USING id;
          END;

        $_$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: authentications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE authentications (
    id integer NOT NULL,
    provider character varying(255) NOT NULL,
    uid character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    auth_token text,
    expires_at timestamp without time zone,
    last_expires_at timestamp without time zone
);


--
-- Name: authentications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE authentications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: authentications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE authentications_id_seq OWNED BY authentications.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE comments (
    id integer NOT NULL,
    comment text,
    commentable_id integer,
    commentable_type character varying(255),
    user_id integer,
    role character varying(255) DEFAULT 'comments'::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    eventable_type character varying DEFAULT 'Comment'::character varying,
    eventable_id character varying
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: corrupt_timelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE corrupt_timelines (
    id integer NOT NULL,
    name character varying,
    description character varying,
    link character varying,
    picture text,
    user_identifier character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    published_at timestamp without time zone,
    feed_type character varying,
    identifier character varying,
    author character varying,
    youtube_id character varying,
    likes_count integer,
    author_picture character varying,
    artist character varying,
    album character varying,
    source character varying,
    source_link character varying,
    youtube_link character varying,
    restricted_users integer[] DEFAULT '{}'::integer[],
    likes integer[] DEFAULT '{}'::integer[],
    enabled boolean DEFAULT true,
    font_color character varying,
    artist_identifier character varying,
    genres character varying[] DEFAULT '{}'::character varying[],
    comments_count integer DEFAULT 0,
    itunes_link character varying,
    stream character varying,
    default_playlist_user_ids integer[] DEFAULT '{}'::integer[],
    activities_count integer,
    import_source character varying DEFAULT 'feed'::character varying,
    category character varying,
    playlist_ids integer[] DEFAULT '{}'::integer[],
    timeline_id integer
);


--
-- Name: corrupt_timelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE corrupt_timelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: corrupt_timelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE corrupt_timelines_id_seq OWNED BY corrupt_timelines.id;


--
-- Name: duplicate_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE duplicate_users (
    id integer NOT NULL,
    email character varying,
    encrypted_password character varying,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role character varying,
    avatar character varying,
    first_name character varying,
    middle_name character varying,
    last_name character varying,
    facebook_link character varying,
    twitter_link character varying,
    google_plus_link character varying,
    linkedin_link character varying,
    facebook_avatar character varying,
    google_plus_avatar character varying,
    linkedin_avatar character varying,
    authentication_token character varying,
    facebook_profile_image_url character varying,
    facebook_id character varying,
    background character varying,
    username character varying,
    comments_count integer DEFAULT 0,
    enabled boolean DEFAULT true,
    likes_count integer DEFAULT 0,
    website text DEFAULT '0'::text,
    genres text,
    user_type character varying,
    followers_count integer,
    followed_count integer,
    friends_count integer,
    user_timelines_count integer DEFAULT 0,
    artist_timelines_count integer DEFAULT 0,
    name character varying,
    is_verified boolean DEFAULT false,
    ext_id character varying,
    restricted_timelines integer[] DEFAULT '{}'::integer[],
    restricted_users character varying[] DEFAULT '{}'::character varying[],
    authenticated boolean DEFAULT false,
    welcome_notified_at timestamp without time zone
);


--
-- Name: duplicate_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE duplicate_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: duplicate_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE duplicate_users_id_seq OWNED BY duplicate_users.id;


--
-- Name: genres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE genres (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: genres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE genres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE genres_id_seq OWNED BY genres.id;


--
-- Name: non_music_artist_followers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE non_music_artist_followers (
    id integer NOT NULL,
    follower_id integer,
    followed_id integer,
    is_followed boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    primary_id_of_user_followers integer
);


--
-- Name: non_music_artist_followers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE non_music_artist_followers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: non_music_artist_followers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE non_music_artist_followers_id_seq OWNED BY non_music_artist_followers.id;


--
-- Name: non_music_artist_timelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE non_music_artist_timelines (
    id integer NOT NULL,
    name character varying,
    description text,
    link text,
    user_identifier character varying,
    picture text,
    feed_type character varying,
    identifier character varying,
    author character varying,
    likes_count integer,
    published_at timestamp without time zone,
    youtube_id character varying,
    author_picture character varying,
    enabled boolean,
    artist character varying,
    album character varying,
    source character varying,
    source_link text,
    youtube_link character varying,
    restricted_users integer[] DEFAULT '{}'::integer[],
    likes integer[] DEFAULT '{}'::integer[],
    font_color character varying,
    artist_identifier character varying,
    genres character varying[] DEFAULT '{}'::character varying[],
    comments_count integer,
    itunes_link character varying,
    stream text,
    default_playlist_user_ids integer[] DEFAULT '{}'::integer[],
    activities_count integer,
    import_source character varying,
    category character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: non_music_artist_timelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE non_music_artist_timelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: non_music_artist_timelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE non_music_artist_timelines_id_seq OWNED BY non_music_artist_timelines.id;


--
-- Name: non_music_category_artists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE non_music_category_artists (
    id integer NOT NULL,
    email character varying,
    encrypted_password character varying,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role character varying,
    avatar character varying,
    first_name character varying,
    middle_name character varying,
    last_name character varying,
    facebook_link character varying,
    twitter_link character varying,
    google_plus_link character varying,
    linkedin_link character varying,
    facebook_avatar character varying,
    google_plus_avatar character varying,
    linkedin_avatar character varying,
    authentication_token character varying,
    facebook_profile_image_url character varying,
    facebook_id character varying,
    background character varying,
    username character varying,
    comments_count integer DEFAULT 0,
    enabled boolean DEFAULT true,
    likes_count integer DEFAULT 0,
    website text DEFAULT '0'::text,
    genres text,
    user_type character varying,
    followers_count integer,
    followed_count integer,
    friends_count integer,
    user_timelines_count integer DEFAULT 0,
    artist_timelines_count integer DEFAULT 0,
    name character varying,
    is_verified boolean DEFAULT false,
    ext_id character varying,
    restricted_timelines integer[] DEFAULT '{}'::integer[],
    restricted_users character varying[] DEFAULT '{}'::character varying[],
    authenticated boolean DEFAULT false,
    category character varying,
    public_playlists_timelines_count integer DEFAULT 0,
    private_playlists_timelines_count integer DEFAULT 0,
    welcome_notified_at timestamp without time zone,
    aggregated_at timestamp without time zone,
    facebook_exception text,
    suggestions_count integer
);


--
-- Name: non_music_category_artists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE non_music_category_artists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: non_music_category_artists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE non_music_category_artists_id_seq OWNED BY non_music_category_artists.id;


--
-- Name: pgbench_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pgbench_accounts (
    aid integer NOT NULL,
    bid integer,
    abalance integer,
    filler character(84)
)
WITH (fillfactor='100');


--
-- Name: pgbench_branches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pgbench_branches (
    bid integer NOT NULL,
    bbalance integer,
    filler character(88)
)
WITH (fillfactor='100');


--
-- Name: pgbench_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pgbench_history (
    tid integer,
    bid integer,
    aid integer,
    delta integer,
    mtime timestamp without time zone,
    filler character(22)
);


--
-- Name: pgbench_tellers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pgbench_tellers (
    tid integer NOT NULL,
    bid integer,
    tbalance integer,
    filler character(84)
)
WITH (fillfactor='100');


--
-- Name: playlists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE playlists (
    id integer NOT NULL,
    title character varying(255),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    timelines_ids integer[] DEFAULT '{}'::integer[],
    picture_url text,
    is_private boolean DEFAULT false NOT NULL,
    import_source character varying
);


--
-- Name: playlists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE playlists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: playlists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE playlists_id_seq OWNED BY playlists.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying(255) NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: timeline_publishers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE timeline_publishers (
    id integer NOT NULL,
    user_identifier character varying,
    timeline_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: timeline_publishers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE timeline_publishers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: timeline_publishers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE timeline_publishers_id_seq OWNED BY timeline_publishers.id;


--
-- Name: timelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE timelines (
    id integer NOT NULL,
    name character varying(255),
    description text,
    link text,
    picture text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    feed_type character varying(255) NOT NULL,
    identifier character varying(255),
    likes_count integer DEFAULT 0,
    published_at timestamp without time zone,
    youtube_id character varying(255),
    enabled boolean DEFAULT true,
    artist character varying(255),
    album character varying(255),
    source character varying(255),
    source_link text,
    youtube_link character varying(255),
    restricted_users integer[] DEFAULT '{}'::integer[],
    likes integer[] DEFAULT '{}'::integer[],
    font_color character varying,
    genres character varying[] DEFAULT '{}'::character varying[],
    comments_count integer DEFAULT 0,
    itunes_link character varying,
    stream text,
    default_playlist_user_ids integer[] DEFAULT '{}'::integer[],
    activities_count integer DEFAULT 0,
    import_source character varying DEFAULT 'feed'::character varying,
    category character varying,
    view_count integer DEFAULT 0,
    change_view_count integer DEFAULT 0
);


--
-- Name: timelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE timelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: timelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE timelines_id_seq OWNED BY timelines.id;


--
-- Name: user_followers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_followers (
    id integer NOT NULL,
    follower_id integer,
    followed_id integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    is_followed boolean DEFAULT true
);


--
-- Name: user_followers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_followers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_followers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_followers_id_seq OWNED BY user_followers.id;


--
-- Name: user_friends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_friends (
    id integer NOT NULL,
    friend1_id integer,
    friend2_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_friends_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_friends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_friends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_friends_id_seq OWNED BY user_friends.id;


--
-- Name: user_genres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_genres (
    id integer NOT NULL,
    user_id integer,
    genre_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_genres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_genres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_genres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_genres_id_seq OWNED BY user_genres.id;


--
-- Name: user_likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_likes (
    id integer NOT NULL,
    user_id integer,
    timeline_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_likes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_likes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_likes_id_seq OWNED BY user_likes.id;


--
-- Name: user_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_notifications (
    id integer NOT NULL,
    to_user_id integer,
    from_user_id integer,
    message character varying,
    alert_type character varying,
    comment character varying,
    timeline_id integer,
    playlist_id integer,
    comment_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    status integer DEFAULT 0,
    artist_ids text[] DEFAULT '{}'::text[]
);


--
-- Name: user_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_notifications_id_seq OWNED BY user_notifications.id;


--
-- Name: user_songs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_songs (
    id integer NOT NULL,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    timeline_id integer
);


--
-- Name: user_songs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_songs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_songs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_songs_id_seq OWNED BY user_songs.id;


--
-- Name: user_timelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_timelines (
    id integer NOT NULL,
    user_id integer,
    timeline_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_timelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_timelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_timelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_timelines_id_seq OWNED BY user_timelines.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    role character varying(255),
    avatar character varying(255),
    first_name character varying(255),
    middle_name character varying(255),
    last_name character varying(255),
    facebook_link character varying(255),
    twitter_link character varying(255),
    google_plus_link character varying(255),
    linkedin_link character varying(255),
    facebook_avatar character varying(255),
    google_plus_avatar character varying(255),
    linkedin_avatar character varying(255),
    authentication_token character varying(255),
    facebook_profile_image_url character varying(255),
    facebook_id character varying(255),
    background character varying(255),
    username character varying,
    comments_count integer DEFAULT 0,
    enabled boolean DEFAULT true,
    website text DEFAULT '0'::text,
    genres text[] DEFAULT '{}'::text[],
    user_type character varying(255) DEFAULT 'user'::character varying NOT NULL,
    followers_count integer DEFAULT 0,
    followed_count integer DEFAULT 0,
    friends_count integer DEFAULT 0,
    name character varying(255) NOT NULL,
    is_verified boolean DEFAULT false,
    ext_id character varying,
    restricted_timelines integer[] DEFAULT '{}'::integer[],
    restricted_users character varying[] DEFAULT '{}'::character varying[],
    welcome_notified_at timestamp without time zone,
    category character varying,
    public_playlists_timelines_count integer DEFAULT 0,
    private_playlists_timelines_count integer DEFAULT 0,
    aggregated_at timestamp without time zone,
    suggestions_count integer DEFAULT 0,
    contact_number character varying,
    contact_list hstore[] DEFAULT '{}'::hstore[],
    phone_artists hstore[] DEFAULT '{}'::hstore[],
    device_id character varying,
    last_feed_viewed_at timestamp without time zone DEFAULT '2015-12-03 09:09:51.499422'::timestamp without time zone,
    secondary_emails text[] DEFAULT '{}'::text[],
    secondary_phones text[] DEFAULT '{}'::text[],
    login_method character varying,
    restricted_suggestions text[] DEFAULT '{}'::text[],
    timelines_count integer DEFAULT 0
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


SET search_path = suggestions, pg_catalog;

--
-- Name: artists; Type: MATERIALIZED VIEW; Schema: suggestions; Owner: -
--

CREATE MATERIALIZED VIEW artists AS
 SELECT DISTINCT users.id,
    users.email,
    users.encrypted_password,
    users.reset_password_token,
    users.reset_password_sent_at,
    users.remember_created_at,
    users.sign_in_count,
    users.current_sign_in_at,
    users.last_sign_in_at,
    users.current_sign_in_ip,
    users.last_sign_in_ip,
    users.created_at,
    users.updated_at,
    users.role,
    users.avatar,
    users.first_name,
    users.middle_name,
    users.last_name,
    users.facebook_link,
    users.twitter_link,
    users.google_plus_link,
    users.linkedin_link,
    users.facebook_avatar,
    users.google_plus_avatar,
    users.linkedin_avatar,
    users.authentication_token,
    users.facebook_profile_image_url,
    users.facebook_id,
    users.background,
    users.username,
    users.comments_count,
    users.enabled,
    users.website,
    users.genres,
    users.user_type,
    users.followers_count,
    users.followed_count,
    users.friends_count,
    users.name,
    users.is_verified,
    users.ext_id,
    users.restricted_timelines,
    users.restricted_users,
    users.welcome_notified_at,
    users.category,
    users.public_playlists_timelines_count,
    users.private_playlists_timelines_count,
    users.aggregated_at,
    users.suggestions_count,
    users.contact_number,
    users.contact_list,
    users.phone_artists,
    users.device_id,
    users.last_feed_viewed_at,
    users.secondary_emails,
    users.secondary_phones,
    users.login_method,
    users.restricted_suggestions,
    users.timelines_count,
    users.is_verified AS is_verified_user,
    users.followers_count AS user_follower_count
   FROM public.users
  WHERE (((users.user_type)::text = 'artist'::text) AND (users.enabled = true) AND (( SELECT count(timeline_publishers.timeline_id) AS count
           FROM public.timeline_publishers
          WHERE ((users.facebook_id)::text = (timeline_publishers.user_identifier)::text)) > 10))
  ORDER BY users.timelines_count DESC, users.followers_count DESC
 LIMIT 200
  WITH NO DATA;


SET search_path = public, pg_catalog;

--
-- Name: authentications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY authentications ALTER COLUMN id SET DEFAULT nextval('authentications_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: corrupt_timelines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY corrupt_timelines ALTER COLUMN id SET DEFAULT nextval('corrupt_timelines_id_seq'::regclass);


--
-- Name: duplicate_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY duplicate_users ALTER COLUMN id SET DEFAULT nextval('duplicate_users_id_seq'::regclass);


--
-- Name: genres id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY genres ALTER COLUMN id SET DEFAULT nextval('genres_id_seq'::regclass);


--
-- Name: non_music_artist_followers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY non_music_artist_followers ALTER COLUMN id SET DEFAULT nextval('non_music_artist_followers_id_seq'::regclass);


--
-- Name: non_music_artist_timelines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY non_music_artist_timelines ALTER COLUMN id SET DEFAULT nextval('non_music_artist_timelines_id_seq'::regclass);


--
-- Name: non_music_category_artists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY non_music_category_artists ALTER COLUMN id SET DEFAULT nextval('non_music_category_artists_id_seq'::regclass);


--
-- Name: playlists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY playlists ALTER COLUMN id SET DEFAULT nextval('playlists_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: timeline_publishers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY timeline_publishers ALTER COLUMN id SET DEFAULT nextval('timeline_publishers_id_seq'::regclass);


--
-- Name: timelines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY timelines ALTER COLUMN id SET DEFAULT nextval('timelines_id_seq'::regclass);


--
-- Name: user_followers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_followers ALTER COLUMN id SET DEFAULT nextval('user_followers_id_seq'::regclass);


--
-- Name: user_friends id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_friends ALTER COLUMN id SET DEFAULT nextval('user_friends_id_seq'::regclass);


--
-- Name: user_genres id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_genres ALTER COLUMN id SET DEFAULT nextval('user_genres_id_seq'::regclass);


--
-- Name: user_likes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_likes ALTER COLUMN id SET DEFAULT nextval('user_likes_id_seq'::regclass);


--
-- Name: user_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_notifications ALTER COLUMN id SET DEFAULT nextval('user_notifications_id_seq'::regclass);


--
-- Name: user_songs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_songs ALTER COLUMN id SET DEFAULT nextval('user_songs_id_seq'::regclass);


--
-- Name: user_timelines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_timelines ALTER COLUMN id SET DEFAULT nextval('user_timelines_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


SET search_path = suggestions, pg_catalog;

--
-- Name: trending_artists; Type: MATERIALIZED VIEW; Schema: suggestions; Owner: -
--

CREATE MATERIALIZED VIEW trending_artists AS
 SELECT DISTINCT users.id,
    users.email,
    users.encrypted_password,
    users.reset_password_token,
    users.reset_password_sent_at,
    users.remember_created_at,
    users.sign_in_count,
    users.current_sign_in_at,
    users.last_sign_in_at,
    users.current_sign_in_ip,
    users.last_sign_in_ip,
    users.created_at,
    users.updated_at,
    users.role,
    users.avatar,
    users.first_name,
    users.middle_name,
    users.last_name,
    users.facebook_link,
    users.twitter_link,
    users.google_plus_link,
    users.linkedin_link,
    users.facebook_avatar,
    users.google_plus_avatar,
    users.linkedin_avatar,
    users.authentication_token,
    users.facebook_profile_image_url,
    users.facebook_id,
    users.background,
    users.username,
    users.comments_count,
    users.enabled,
    users.website,
    users.genres,
    users.user_type,
    users.followers_count,
    users.followed_count,
    users.friends_count,
    users.name,
    users.is_verified,
    users.ext_id,
    users.restricted_timelines,
    users.restricted_users,
    users.welcome_notified_at,
    users.category,
    users.public_playlists_timelines_count,
    users.private_playlists_timelines_count,
    users.aggregated_at,
    users.suggestions_count,
    users.contact_number,
    users.contact_list,
    users.phone_artists,
    users.device_id,
    users.last_feed_viewed_at,
    users.secondary_emails,
    users.secondary_phones,
    users.login_method,
    users.restricted_suggestions,
    users.timelines_count,
    count(user_followers.id) AS user_follower_count,
    users.is_verified AS is_verified_user
   FROM (public.users
     JOIN public.user_followers ON ((users.id = user_followers.followed_id)))
  WHERE (((users.user_type)::text = 'artist'::text) AND (user_followers.created_at > (('now'::text)::date - '30 days'::interval day)))
  GROUP BY users.id
  ORDER BY (count(user_followers.id)) DESC
 LIMIT 50
  WITH NO DATA;


SET search_path = public, pg_catalog;

--
-- Name: authentications authentications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY authentications
    ADD CONSTRAINT authentications_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: corrupt_timelines corrupt_timelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY corrupt_timelines
    ADD CONSTRAINT corrupt_timelines_pkey PRIMARY KEY (id);


--
-- Name: duplicate_users duplicate_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY duplicate_users
    ADD CONSTRAINT duplicate_users_pkey PRIMARY KEY (id);


--
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (id);


--
-- Name: non_music_artist_followers non_music_artist_followers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY non_music_artist_followers
    ADD CONSTRAINT non_music_artist_followers_pkey PRIMARY KEY (id);


--
-- Name: non_music_artist_timelines non_music_artist_timelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY non_music_artist_timelines
    ADD CONSTRAINT non_music_artist_timelines_pkey PRIMARY KEY (id);


--
-- Name: non_music_category_artists non_music_category_artists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY non_music_category_artists
    ADD CONSTRAINT non_music_category_artists_pkey PRIMARY KEY (id);


--
-- Name: pgbench_accounts pgbench_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pgbench_accounts
    ADD CONSTRAINT pgbench_accounts_pkey PRIMARY KEY (aid);


--
-- Name: pgbench_branches pgbench_branches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pgbench_branches
    ADD CONSTRAINT pgbench_branches_pkey PRIMARY KEY (bid);


--
-- Name: pgbench_tellers pgbench_tellers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pgbench_tellers
    ADD CONSTRAINT pgbench_tellers_pkey PRIMARY KEY (tid);


--
-- Name: playlists playlists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY playlists
    ADD CONSTRAINT playlists_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: timelines timelines_identifier_unique_contraint; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY timelines
    ADD CONSTRAINT timelines_identifier_unique_contraint UNIQUE (identifier);


--
-- Name: timelines timelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY timelines
    ADD CONSTRAINT timelines_pkey PRIMARY KEY (id);


--
-- Name: user_followers user_followers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_followers
    ADD CONSTRAINT user_followers_pkey PRIMARY KEY (id);


--
-- Name: user_friends user_friends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_friends
    ADD CONSTRAINT user_friends_pkey PRIMARY KEY (id);


--
-- Name: user_genres user_genres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_genres
    ADD CONSTRAINT user_genres_pkey PRIMARY KEY (id);


--
-- Name: user_likes user_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_likes
    ADD CONSTRAINT user_likes_pkey PRIMARY KEY (id);


--
-- Name: user_notifications user_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_notifications
    ADD CONSTRAINT user_notifications_pkey PRIMARY KEY (id);


--
-- Name: user_songs user_songs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_songs
    ADD CONSTRAINT user_songs_pkey PRIMARY KEY (id);


--
-- Name: user_timelines user_timelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_timelines
    ADD CONSTRAINT user_timelines_pkey PRIMARY KEY (id);


--
-- Name: index_authentications_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentications_on_email ON authentications USING btree (email);


--
-- Name: index_authentications_on_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentications_on_provider ON authentications USING btree (provider);


--
-- Name: index_authentications_on_provider_and_uid_and_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentications_on_provider_and_uid_and_email ON authentications USING btree (provider, uid, email);


--
-- Name: index_authentications_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentications_on_uid ON authentications USING btree (uid);


--
-- Name: index_authentications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentications_on_user_id ON authentications USING btree (user_id);


--
-- Name: index_authentications_on_user_id_and_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_authentications_on_user_id_and_provider ON authentications USING btree (user_id, provider);


--
-- Name: index_comments_on_commentable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable_id ON comments USING btree (commentable_id);


--
-- Name: index_comments_on_commentable_id_and_commentable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable_id_and_commentable_type ON comments USING btree (commentable_id, commentable_type);


--
-- Name: index_comments_on_commentable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable_type ON comments USING btree (commentable_type);


--
-- Name: index_comments_on_created_at_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_created_at_desc ON comments USING btree (created_at DESC NULLS LAST);


--
-- Name: index_comments_on_eventable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_eventable_type ON comments USING btree (eventable_type);


--
-- Name: index_comments_on_user_id_asc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id_asc ON comments USING btree (user_id);


--
-- Name: index_playlists_on_is_private; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_playlists_on_is_private ON playlists USING btree (is_private);


--
-- Name: index_playlists_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_playlists_on_user_id ON playlists USING btree (user_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_timeline_publishers_on_created_at_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timeline_publishers_on_created_at_desc ON timelines USING btree (created_at DESC NULLS LAST);


--
-- Name: index_timeline_publishers_on_timeline_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timeline_publishers_on_timeline_id ON timeline_publishers USING btree (timeline_id);


--
-- Name: index_timeline_publishers_on_timeline_id_created_at_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timeline_publishers_on_timeline_id_created_at_desc ON timeline_publishers USING btree (timeline_id, created_at DESC NULLS LAST);


--
-- Name: index_timeline_publishers_on_user_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timeline_publishers_on_user_identifier ON timeline_publishers USING btree (user_identifier);


--
-- Name: index_timeline_publishers_on_user_identifier_and_timeline_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_timeline_publishers_on_user_identifier_and_timeline_id ON timeline_publishers USING btree (user_identifier, timeline_id);


--
-- Name: index_timelines_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timelines_on_created_at ON timelines USING btree (created_at);


--
-- Name: index_timelines_on_feed_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timelines_on_feed_type ON timelines USING btree (feed_type);


--
-- Name: index_timelines_on_id_asc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timelines_on_id_asc ON timelines USING btree (id);


--
-- Name: index_timelines_on_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timelines_on_identifier ON timelines USING btree (identifier);


--
-- Name: index_timelines_on_published_at_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timelines_on_published_at_desc ON timelines USING btree (published_at DESC NULLS LAST);


--
-- Name: index_timelines_on_source_link; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timelines_on_source_link ON timelines USING btree (source_link);


--
-- Name: index_timelines_on_youtube_link; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timelines_on_youtube_link ON timelines USING btree (youtube_link);


--
-- Name: index_timelines_on_youtube_link_and_source_link_and_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_timelines_on_youtube_link_and_source_link_and_identifier ON timelines USING btree (youtube_link, source_link, identifier);


--
-- Name: index_user_followers_on_followed_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_followers_on_followed_id ON user_followers USING btree (followed_id);


--
-- Name: index_user_followers_on_follower_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_followers_on_follower_id ON user_followers USING btree (follower_id);


--
-- Name: index_user_friends_on_friend1_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_friends_on_friend1_id ON user_friends USING btree (friend1_id);


--
-- Name: index_user_friends_on_friend1_id_and_friend2_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_friends_on_friend1_id_and_friend2_id ON user_friends USING btree (friend1_id, friend2_id);


--
-- Name: index_user_friends_on_friend2_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_friends_on_friend2_id ON user_friends USING btree (friend2_id);


--
-- Name: index_user_friends_on_friend2_id_and_friend1_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_friends_on_friend2_id_and_friend1_id ON user_friends USING btree (friend2_id, friend1_id);


--
-- Name: index_user_genres_on_genre_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_genres_on_genre_id ON user_genres USING btree (genre_id);


--
-- Name: index_user_genres_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_genres_on_user_id ON user_genres USING btree (user_id);


--
-- Name: index_user_genres_on_user_id_and_genre_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_genres_on_user_id_and_genre_id ON user_genres USING btree (user_id, genre_id);


--
-- Name: index_user_likes_on_timeline_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_likes_on_timeline_id ON user_likes USING btree (timeline_id);


--
-- Name: index_user_likes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_likes_on_user_id ON user_likes USING btree (user_id);


--
-- Name: index_user_likeson_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_likeson_created_at ON user_likes USING btree (created_at);


--
-- Name: index_user_notifications_on_alert_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notifications_on_alert_type ON user_notifications USING btree (alert_type);


--
-- Name: index_user_notifications_on_created_at_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notifications_on_created_at_desc ON user_notifications USING btree (created_at DESC NULLS LAST);


--
-- Name: index_user_notifications_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_notifications_on_status ON user_notifications USING btree (status);


--
-- Name: index_users_on_authentication_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_authentication_token ON users USING btree (authentication_token);


--
-- Name: index_users_on_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_category ON users USING btree (category);


--
-- Name: index_users_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_created_at ON users USING btree (created_at);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_enabled ON users USING btree (enabled);


--
-- Name: index_users_on_ext_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_ext_id ON users USING btree (ext_id);


--
-- Name: index_users_on_facebook_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_facebook_id ON users USING btree (facebook_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_user_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_user_type ON users USING btree (user_type);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_username ON users USING btree (username);


--
-- Name: playlists_timelines_ids_rdtree_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX playlists_timelines_ids_rdtree_idx ON playlists USING gist (timelines_ids);


--
-- Name: timelines_likes_rdtree_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX timelines_likes_rdtree_idx ON timelines USING gist (likes);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: timeline_publishers update_users_timelines_count; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_users_timelines_count AFTER INSERT OR DELETE OR UPDATE ON timeline_publishers FOR EACH ROW EXECUTE PROCEDURE counter_cache_text('users', 'facebook_id', 'user_identifier', 'timelines_count');


--
-- Name: user_likes update_users_timelines_count; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_users_timelines_count AFTER INSERT OR DELETE OR UPDATE ON user_likes FOR EACH ROW EXECUTE PROCEDURE counter_cache('users', 'id', 'user_id', 'timelines_count');


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20150212140546');

INSERT INTO schema_migrations (version) VALUES ('20150213163844');

INSERT INTO schema_migrations (version) VALUES ('20150217143701');

INSERT INTO schema_migrations (version) VALUES ('20150217145556');

INSERT INTO schema_migrations (version) VALUES ('20150217163916');

INSERT INTO schema_migrations (version) VALUES ('20150220082233');

INSERT INTO schema_migrations (version) VALUES ('20150220102642');

INSERT INTO schema_migrations (version) VALUES ('20150221155834');

INSERT INTO schema_migrations (version) VALUES ('20150221160823');

INSERT INTO schema_migrations (version) VALUES ('20150222022151');

INSERT INTO schema_migrations (version) VALUES ('20150223042307');

INSERT INTO schema_migrations (version) VALUES ('20150224030005');

INSERT INTO schema_migrations (version) VALUES ('20150225014413');

INSERT INTO schema_migrations (version) VALUES ('20150225040530');

INSERT INTO schema_migrations (version) VALUES ('20150316160009');

INSERT INTO schema_migrations (version) VALUES ('20150317054553');

INSERT INTO schema_migrations (version) VALUES ('20150317065834');

INSERT INTO schema_migrations (version) VALUES ('20150317072527');

INSERT INTO schema_migrations (version) VALUES ('20150318004231');

INSERT INTO schema_migrations (version) VALUES ('20150318041153');

INSERT INTO schema_migrations (version) VALUES ('20150318063610');

INSERT INTO schema_migrations (version) VALUES ('20150318073118');

INSERT INTO schema_migrations (version) VALUES ('20150319115825');

INSERT INTO schema_migrations (version) VALUES ('20150320032121');

INSERT INTO schema_migrations (version) VALUES ('20150320081321');

INSERT INTO schema_migrations (version) VALUES ('20150320082906');

INSERT INTO schema_migrations (version) VALUES ('20150320093046');

INSERT INTO schema_migrations (version) VALUES ('20150323134606');

INSERT INTO schema_migrations (version) VALUES ('20150323134827');

INSERT INTO schema_migrations (version) VALUES ('20150323140752');

INSERT INTO schema_migrations (version) VALUES ('20150323163717');

INSERT INTO schema_migrations (version) VALUES ('20150325144110');

INSERT INTO schema_migrations (version) VALUES ('20150326130659');

INSERT INTO schema_migrations (version) VALUES ('20150409180155');

INSERT INTO schema_migrations (version) VALUES ('20150410181346');

INSERT INTO schema_migrations (version) VALUES ('20150416073455');

INSERT INTO schema_migrations (version) VALUES ('20150416095006');

INSERT INTO schema_migrations (version) VALUES ('20150520143615');

INSERT INTO schema_migrations (version) VALUES ('20150521085145');

INSERT INTO schema_migrations (version) VALUES ('20150527190537');

INSERT INTO schema_migrations (version) VALUES ('20150603070523');

INSERT INTO schema_migrations (version) VALUES ('20150611140623');

INSERT INTO schema_migrations (version) VALUES ('20150611141048');

INSERT INTO schema_migrations (version) VALUES ('20150612142246');

INSERT INTO schema_migrations (version) VALUES ('20150616111505');

INSERT INTO schema_migrations (version) VALUES ('20150619071009');

INSERT INTO schema_migrations (version) VALUES ('20150624124516');

INSERT INTO schema_migrations (version) VALUES ('20150630182952');

INSERT INTO schema_migrations (version) VALUES ('20150630213705');

INSERT INTO schema_migrations (version) VALUES ('20150708114047');

INSERT INTO schema_migrations (version) VALUES ('20150710145611');

INSERT INTO schema_migrations (version) VALUES ('20150723165735');

INSERT INTO schema_migrations (version) VALUES ('20150729131033');

INSERT INTO schema_migrations (version) VALUES ('20150729143815');

INSERT INTO schema_migrations (version) VALUES ('20150804142121');

INSERT INTO schema_migrations (version) VALUES ('20150804151814');

INSERT INTO schema_migrations (version) VALUES ('20150819092359');

INSERT INTO schema_migrations (version) VALUES ('20150825074740');

INSERT INTO schema_migrations (version) VALUES ('20150910114603');

INSERT INTO schema_migrations (version) VALUES ('20150922150139');

INSERT INTO schema_migrations (version) VALUES ('20150928131029');

INSERT INTO schema_migrations (version) VALUES ('20151013093945');

INSERT INTO schema_migrations (version) VALUES ('20151026150209');

INSERT INTO schema_migrations (version) VALUES ('20151026150234');

INSERT INTO schema_migrations (version) VALUES ('20151026150607');

INSERT INTO schema_migrations (version) VALUES ('20151030203807');

INSERT INTO schema_migrations (version) VALUES ('20151105163522');

INSERT INTO schema_migrations (version) VALUES ('20151105173332');

INSERT INTO schema_migrations (version) VALUES ('20151107102030');

INSERT INTO schema_migrations (version) VALUES ('20151107114023');

INSERT INTO schema_migrations (version) VALUES ('20151108145840');

INSERT INTO schema_migrations (version) VALUES ('20151113123653');

INSERT INTO schema_migrations (version) VALUES ('20151122080409');

INSERT INTO schema_migrations (version) VALUES ('20151201182822');

INSERT INTO schema_migrations (version) VALUES ('20151210224803');

INSERT INTO schema_migrations (version) VALUES ('20151222131954');

INSERT INTO schema_migrations (version) VALUES ('20151223150629');

INSERT INTO schema_migrations (version) VALUES ('20151224193325');

INSERT INTO schema_migrations (version) VALUES ('20151228192228');

INSERT INTO schema_migrations (version) VALUES ('20151228214139');

INSERT INTO schema_migrations (version) VALUES ('20151229201105');

INSERT INTO schema_migrations (version) VALUES ('20151231173438');

INSERT INTO schema_migrations (version) VALUES ('20151231174713');

INSERT INTO schema_migrations (version) VALUES ('20160101220807');

INSERT INTO schema_migrations (version) VALUES ('20160112021741');

INSERT INTO schema_migrations (version) VALUES ('20160112021906');

INSERT INTO schema_migrations (version) VALUES ('20160120193911');

INSERT INTO schema_migrations (version) VALUES ('20160120230827');

INSERT INTO schema_migrations (version) VALUES ('20160124210435');

INSERT INTO schema_migrations (version) VALUES ('20160124210547');

INSERT INTO schema_migrations (version) VALUES ('20160127185522');

INSERT INTO schema_migrations (version) VALUES ('20160129183244');

INSERT INTO schema_migrations (version) VALUES ('20160204205135');

INSERT INTO schema_migrations (version) VALUES ('20160211090359');

