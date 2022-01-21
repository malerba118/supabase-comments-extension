--
-- PostgreSQL database dump
--

-- Dumped from database version 14.1 (Debian 14.1-1.pgdg110+1)
-- Dumped by pg_dump version 14.1 (Debian 14.1-1.pgdg110+1)

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
-- Name: auth; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO supabase_admin;

--
-- Name: comments; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA comments;


ALTER SCHEMA comments OWNER TO postgres;

--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA extensions;


ALTER SCHEMA extensions OWNER TO postgres;

--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA realtime;


ALTER SCHEMA realtime OWNER TO postgres;

--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: supabase_admin
--

CREATE SCHEMA storage;


ALTER SCHEMA storage OWNER TO supabase_admin;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: pgjwt; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA extensions;


--
-- Name: EXTENSION pgjwt; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgjwt IS 'JSON Web Token API for Postgresql';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: postgres
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


ALTER TYPE realtime.action OWNER TO postgres;

--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: postgres
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte'
);


ALTER TYPE realtime.equality_op OWNER TO postgres;

--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: postgres
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


ALTER TYPE realtime.user_defined_filter OWNER TO postgres;

--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: postgres
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type text,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


ALTER TYPE realtime.wal_column OWNER TO postgres;

--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: postgres
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	users uuid[],
	errors text[]
);


ALTER TYPE realtime.wal_rls OWNER TO postgres;

--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  	coalesce(
		current_setting('request.jwt.claim.email', true),
		(current_setting('request.jwt.claims', true)::jsonb ->> 'email')
	)::text
$$;


ALTER FUNCTION auth.email() OWNER TO supabase_auth_admin;

--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  	coalesce(
		current_setting('request.jwt.claim.role', true),
		(current_setting('request.jwt.claims', true)::jsonb ->> 'role')
	)::text
$$;


ALTER FUNCTION auth.role() OWNER TO supabase_auth_admin;

--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: supabase_auth_admin
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select
  nullif(
    coalesce(
      current_setting('request.jwt.claim.sub', true),
      (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    ),
    ''
  )::uuid
$$;


ALTER FUNCTION auth.uid() OWNER TO supabase_auth_admin;

--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: postgres
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  schema_is_cron bool;
BEGIN
  schema_is_cron = (
    SELECT n.nspname = 'cron'
    FROM pg_event_trigger_ddl_commands() AS ev
    LEFT JOIN pg_catalog.pg_namespace AS n
      ON ev.objid = n.oid
  );

  IF schema_is_cron
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;

  END IF;

END;
$$;


ALTER FUNCTION extensions.grant_pg_cron_access() OWNER TO postgres;

--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: postgres
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: postgres
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
    ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
    ALTER function net.http_collect_response(request_id bigint, async boolean) SECURITY DEFINER;

    ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
    ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
    ALTER function net.http_collect_response(request_id bigint, async boolean) SET search_path = net;

    REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
    REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
    REVOKE ALL ON FUNCTION net.http_collect_response(request_id bigint, async boolean) FROM PUBLIC;

    GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    GRANT EXECUTE ON FUNCTION net.http_collect_response(request_id bigint, async boolean) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
  END IF;
END;
$$;


ALTER FUNCTION extensions.grant_pg_net_access() OWNER TO postgres;

--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: postgres
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: notify_api_restart(); Type: FUNCTION; Schema: extensions; Owner: postgres
--

CREATE FUNCTION extensions.notify_api_restart() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NOTIFY ddl_command_end;
END;
$$;


ALTER FUNCTION extensions.notify_api_restart() OWNER TO postgres;

--
-- Name: FUNCTION notify_api_restart(); Type: COMMENT; Schema: extensions; Owner: postgres
--

COMMENT ON FUNCTION extensions.notify_api_restart() IS 'Sends a notification to the API to restart. If your database schema has changed, this is required so that Supabase can rebuild the relationships.';


--
-- Name: pgrst_watch(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pgrst_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NOTIFY pgrst, 'reload schema';
END;
$$;


ALTER FUNCTION public.pgrst_watch() OWNER TO postgres;

--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: postgres
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
    declare
      -- Regclass of the table e.g. public.notes
      entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

      -- I, U, D, T: insert, update ...
      action realtime.action = (
        case wal ->> 'action'
          when 'I' then 'INSERT'
          when 'U' then 'UPDATE'
          when 'D' then 'DELETE'
          when 'T' then 'TRUNCATE'
          else 'ERROR'
        end
      );

      -- Is row level security enabled for the table
      is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

      -- Subscription vars
      user_id uuid;
      email varchar(255);
      user_has_access bool;
      is_visible_to_user boolean;
      visible_to_user_ids uuid[] = '{}';

      -- user subscriptions to the wal record's table
      subscriptions realtime.subscription[] =
        array_agg(sub)
        from
          realtime.subscription sub
        where
          sub.entity = entity_;

      -- structured info for wal's columns
      columns realtime.wal_column[] =
        array_agg(
          (
            x->>'name',
            x->>'type',
            realtime.cast((x->'value') #>> '{}', (x->>'type')::regtype),
            (pks ->> 'name') is not null,
            pg_catalog.has_column_privilege('authenticated', entity_, x->>'name', 'SELECT')
          )::realtime.wal_column
        )
        from
          jsonb_array_elements(wal -> 'columns') x
          left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

      -- previous identity values for update/delete
      old_columns realtime.wal_column[] =
        array_agg(
          (
            x->>'name',
            x->>'type',
            realtime.cast((x->'value') #>> '{}', (x->>'type')::regtype),
            (pks ->> 'name') is not null,
            pg_catalog.has_column_privilege('authenticated', entity_, x->>'name', 'SELECT')
          )::realtime.wal_column
        )
        from
          jsonb_array_elements(wal -> 'identity') x
          left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

      output jsonb;

      -- Error states
      error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;
      error_unauthorized boolean = not pg_catalog.has_any_column_privilege('authenticated', entity_, 'SELECT');

      errors text[] = case
        when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
        else '{}'::text[]
      end;
    begin

      -- The 'authenticated' user does not have SELECT permission on any of the columns for the entity_
      if error_unauthorized is true then
        return (
          null,
          null,
          visible_to_user_ids,
          array['Error 401: Unauthorized']
        )::realtime.wal_rls;
      end if;

      -------------------------------
      -- Build Output JSONB Object --
      -------------------------------
      output = jsonb_build_object(
        'schema', wal ->> 'schema',
        'table', wal ->> 'table',
        'type', action,
        'commit_timestamp', (wal ->> 'timestamp')::text::timestamp with time zone,
        'columns', (
          select
            jsonb_agg(
              jsonb_build_object(
                'name', pa.attname,
                'type', pt.typname
              )
              order by pa.attnum asc
            )
            from
              pg_attribute pa
              join pg_type pt
                on pa.atttypid = pt.oid
            where
              attrelid = entity_
              and attnum > 0
              and pg_catalog.has_column_privilege('authenticated', entity_, pa.attname, 'SELECT')
        )
      )
      -- Add "record" key for insert and update
      || case
        when error_record_exceeds_max_size then jsonb_build_object('record', '{}'::jsonb)
        when action in ('INSERT', 'UPDATE') then
          jsonb_build_object(
            'record',
            (select jsonb_object_agg((c).name, (c).value) from unnest(columns) c where (c).is_selectable)
          )
        else '{}'::jsonb
      end
      -- Add "old_record" key for update and delete
      || case
        when error_record_exceeds_max_size then jsonb_build_object('old_record', '{}'::jsonb)
        when action in ('UPDATE', 'DELETE') then
          jsonb_build_object(
            'old_record',
            (select jsonb_object_agg((c).name, (c).value) from unnest(old_columns) c where (c).is_selectable)
          )
        else '{}'::jsonb
      end;

      if action in ('TRUNCATE', 'DELETE') then
        visible_to_user_ids = array_agg(s.user_id) from unnest(subscriptions) s;
      else
        -- If RLS is on and someone is subscribed to the table prep
        if is_rls_enabled and array_length(subscriptions, 1) > 0 then
          perform set_config('role', 'authenticated', true);
          if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
            deallocate walrus_rls_stmt;
          end if;
          execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);

        end if;

        -- For each subscribed user
        for user_id, email, is_visible_to_user in (
          select
            subs.user_id,
            subs.email,
            realtime.is_visible_through_filters(columns, subs.filters)
          from
            unnest(subscriptions) subs
        )
        loop
          if is_visible_to_user then
            -- If RLS is off, add to visible users
            if not is_rls_enabled then
              visible_to_user_ids = visible_to_user_ids || user_id;
            else
              -- Check if RLS allows the user to see the record
              perform
                set_config(
                  'request.jwt.claims',
                  jsonb_build_object(
                    'sub', user_id::text,
                    'email', email::text,
                    'role', 'authenticated'
                  )::text,
                  true
                );
              execute 'execute walrus_rls_stmt' into user_has_access;

              if user_has_access then
                visible_to_user_ids = visible_to_user_ids || user_id;
              end if;

              end if;
            end if;
        end loop;

        perform (
          set_config('role', null, true)
        );

    end if;

    return (
      output,
      is_rls_enabled,
      visible_to_user_ids,
      errors
    )::realtime.wal_rls;
  end;
  $$;


ALTER FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) OWNER TO postgres;

--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: postgres
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
    /*
    Builds a sql string that, if executed, creates a prepared statement to
    tests retrive a row from *entity* by its primary key columns.

    Example
      select realtime.build_prepared_statment_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
    */
      select
    'prepare ' || prepared_statement_name || ' as
      select
        exists(
          select
            1
          from
            ' || entity || '
          where
            ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
        )'
      from
        unnest(columns) pkc
      where
        pkc.is_pkey
      group by
        entity
    $$;


ALTER FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) OWNER TO postgres;

--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: postgres
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
    declare
      res jsonb;
    begin
      execute format('select to_jsonb(%L::'|| type_::text || ')', val)  into res;
      return res;
    end
    $$;


ALTER FUNCTION realtime."cast"(val text, type_ regtype) OWNER TO postgres;

--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: postgres
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
    /*
    Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
    */
    declare
      op_symbol text = (
        case
          when op = 'eq' then '='
          when op = 'neq' then '!='
          when op = 'lt' then '<'
          when op = 'lte' then '<='
          when op = 'gt' then '>'
          when op = 'gte' then '>='
          else 'UNKNOWN OP'
        end
      );
      res boolean;
    begin
      execute format('select %L::'|| type_::text || ' ' || op_symbol || ' %L::'|| type_::text, val_1, val_2) into res;
      return res;
    end;
    $$;


ALTER FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) OWNER TO postgres;

--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: postgres
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
    select
      -- Default to allowed when no filters present
      coalesce(
        sum(
          realtime.check_equality_op(
            op:=f.op,
            type_:=col.type::regtype,
            -- cast jsonb to text
            val_1:=col.value #>> '{}',
            val_2:=f.value
          )::int
        ) = count(1),
        true
      )
    from
      unnest(filters) f
      join unnest(columns) col
          on f.column_name = col.name;
    $$;


ALTER FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) OWNER TO postgres;

--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: postgres
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $$;


ALTER FUNCTION realtime.quote_wal2json(entity regclass) OWNER TO postgres;

--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: postgres
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that 'authenticated' may access
    - values are coercable to the correct column type
    */
    declare
      col_names text[] = coalesce(
        array_agg(c.column_name order by c.ordinal_position),
        '{}'::text[]
      )
        from
          information_schema.columns c
        where
          (quote_ident(c.table_schema) || '.' || quote_ident(c.table_name))::regclass = new.entity
          and pg_catalog.has_column_privilege('authenticated', new.entity, c.column_name, 'SELECT');
      filter realtime.user_defined_filter;
      col_type regtype;
    begin
      for filter in select * from unnest(new.filters) loop
        -- Filtered column is valid
        if not filter.column_name = any(col_names) then
          raise exception 'invalid column for filter %', filter.column_name;
        end if;

        -- Type is sanitized and safe for string interpolation
        col_type = (
          select atttypid::regtype
          from pg_catalog.pg_attribute
          where attrelid = new.entity
            and attname = filter.column_name
        );
        if col_type is null then
          raise exception 'failed to lookup type for column %', filter.column_name;
        end if;
        -- raises an exception if value is not coercable to type
        perform realtime.cast(filter.value, col_type);
      end loop;

      -- Apply consistent order to filters so the unique constraint on
      -- (user_id, entity, filters) can't be tricked by a different filter order
      new.filters = coalesce(
        array_agg(f order by f.column_name, f.op, f.value),
        '{}'
      ) from unnest(new.filters) f;

      return new;
    end;
    $$;


ALTER FUNCTION realtime.subscription_check_filters() OWNER TO postgres;

--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
_filename text;
BEGIN
	select string_to_array(name, '/') into _parts;
	select _parts[array_length(_parts,1)] into _filename;
	-- @todo return the last part instead of 2
	return split_part(_filename, '.', 2);
END
$$;


ALTER FUNCTION storage.extension(name text) OWNER TO supabase_storage_admin;

--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


ALTER FUNCTION storage.filename(name text) OWNER TO supabase_storage_admin;

--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[1:array_length(_parts,1)-1];
END
$$;


ALTER FUNCTION storage.foldername(name text) OWNER TO supabase_storage_admin;

--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::int) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


ALTER FUNCTION storage.get_size_by_bucket() OWNER TO supabase_storage_admin;

--
-- Name: search(text, text, integer, integer, integer); Type: FUNCTION; Schema: storage; Owner: supabase_storage_admin
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql
    AS $$
BEGIN
	return query 
		with files_folders as (
			select path_tokens[levels] as folder
			from storage.objects
			where objects.name ilike prefix || '%'
			and bucket_id = bucketname
			GROUP by folder
			limit limits
			offset offsets
		) 
		select files_folders.folder as name, objects.id, objects.updated_at, objects.created_at, objects.last_accessed_at, objects.metadata from files_folders 
		left join storage.objects
		on prefix || files_folders.folder = objects.name and objects.bucket_id=bucketname;
END
$$;


ALTER FUNCTION storage.search(prefix text, bucketname text, limits integer, levels integer, offsets integer) OWNER TO supabase_storage_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone
);


ALTER TABLE auth.audit_log_entries OWNER TO supabase_auth_admin;

--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.identities (
    id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE auth.identities OWNER TO supabase_auth_admin;

--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE auth.instances OWNER TO supabase_auth_admin;

--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255)
);


ALTER TABLE auth.refresh_tokens OWNER TO supabase_auth_admin;

--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: supabase_auth_admin
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE auth.refresh_tokens_id_seq OWNER TO supabase_auth_admin;

--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: supabase_auth_admin
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE auth.schema_migrations OWNER TO supabase_auth_admin;

--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: supabase_auth_admin
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone character varying(15) DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change character varying(15) DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


ALTER TABLE auth.users OWNER TO supabase_auth_admin;

--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: supabase_auth_admin
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: comment_reactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comment_reactions (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    comment_id uuid NOT NULL,
    user_id uuid NOT NULL,
    reaction_type character varying NOT NULL
);


ALTER TABLE public.comment_reactions OWNER TO postgres;

--
-- Name: comment_reactions_metadata; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.comment_reactions_metadata AS
 SELECT comment_reactions.comment_id,
    comment_reactions.reaction_type,
    count(*) AS reaction_count,
    bool_or((comment_reactions.user_id = auth.uid())) AS active_for_user
   FROM public.comment_reactions
  GROUP BY comment_reactions.comment_id, comment_reactions.reaction_type;


ALTER TABLE public.comment_reactions_metadata OWNER TO postgres;

--
-- Name: comment_reactions_metadata_two; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.comment_reactions_metadata_two AS
 SELECT comment_reactions.comment_id,
    comment_reactions.reaction_type,
    count(*) AS reaction_count
   FROM public.comment_reactions
  GROUP BY comment_reactions.comment_id, comment_reactions.reaction_type;


ALTER TABLE public.comment_reactions_metadata_two OWNER TO postgres;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comments (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    topic character varying NOT NULL,
    comment character varying NOT NULL,
    user_id uuid NOT NULL,
    parent_id uuid,
    mentioned_user_ids uuid[] DEFAULT '{}'::uuid[] NOT NULL
);


ALTER TABLE public.comments OWNER TO postgres;

--
-- Name: comments_with_metadata; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.comments_with_metadata AS
 SELECT comments.id,
    comments.created_at,
    comments.topic,
    comments.comment,
    comments.user_id,
    comments.parent_id,
    comments.mentioned_user_ids,
    ( SELECT count(*) AS count
           FROM public.comments c
          WHERE (c.parent_id = comments.id)) AS replies_count
   FROM public.comments;


ALTER TABLE public.comments_with_metadata OWNER TO postgres;

--
-- Name: display_users; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.display_users AS
 SELECT users.id,
    COALESCE((users.raw_user_meta_data ->> 'name'::text), (users.raw_user_meta_data ->> 'full_name'::text), (users.raw_user_meta_data ->> 'user_name'::text)) AS name,
    COALESCE((users.raw_user_meta_data ->> 'avatar_url'::text), (users.raw_user_meta_data ->> 'avatar'::text)) AS avatar
   FROM auth.users;


ALTER TABLE public.display_users OWNER TO postgres;

--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    name character varying,
    avatar character varying
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- Name: reactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reactions (
    type character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    metadata jsonb
);


ALTER TABLE public.reactions OWNER TO postgres;

--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: postgres
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


ALTER TABLE realtime.schema_migrations OWNER TO postgres;

--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: postgres
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    email character varying(255),
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


ALTER TABLE realtime.subscription OWNER TO postgres;

--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: postgres
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false
);


ALTER TABLE storage.buckets OWNER TO supabase_storage_admin;

--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE storage.migrations OWNER TO supabase_storage_admin;

--
-- Name: objects; Type: TABLE; Schema: storage; Owner: supabase_storage_admin
--

CREATE TABLE storage.objects (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED
);


ALTER TABLE storage.objects OWNER TO supabase_storage_admin;

--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at) FROM stdin;
00000000-0000-0000-0000-000000000000	04d72aec-91bd-492c-9bbe-5fd7db670291	{"action":"user_signedup","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"team","timestamp":"2022-01-13T22:01:28Z"}	2022-01-13 22:01:28.780543+00
00000000-0000-0000-0000-000000000000	9eae5e85-a5c5-4e37-a43a-d012cc1ff01f	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:01:28Z"}	2022-01-13 22:01:28.791347+00
00000000-0000-0000-0000-000000000000	1ce3707d-ad47-46ed-9c8c-9ec9fe6a1610	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:03:50Z"}	2022-01-13 22:03:50.541106+00
00000000-0000-0000-0000-000000000000	2884c3f8-a0a9-4159-9555-8be785071b90	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:04:10Z"}	2022-01-13 22:04:10.119551+00
00000000-0000-0000-0000-000000000000	febea105-1530-4677-84d4-4fecf6087fbe	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:04:20Z"}	2022-01-13 22:04:20.747035+00
00000000-0000-0000-0000-000000000000	30a3cb8a-aa71-42da-9631-b0750afa43e0	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:04:35Z"}	2022-01-13 22:04:35.272219+00
00000000-0000-0000-0000-000000000000	e9453eab-5023-4559-a1ce-d61faa1afc36	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:04:41Z"}	2022-01-13 22:04:41.504602+00
00000000-0000-0000-0000-000000000000	ec052f9d-fe97-457f-bdfe-c1ce506f33d3	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:04:43Z"}	2022-01-13 22:04:43.764107+00
00000000-0000-0000-0000-000000000000	b9565856-2fab-4d9f-9e8d-8ac956306f4e	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:04:46Z"}	2022-01-13 22:04:46.082611+00
00000000-0000-0000-0000-000000000000	f5200fce-1705-4908-85b7-16ce0540a9e3	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:04:47Z"}	2022-01-13 22:04:47.292074+00
00000000-0000-0000-0000-000000000000	138d97f6-7b77-4ff9-927d-3a884818378d	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:04:50Z"}	2022-01-13 22:04:50.286771+00
00000000-0000-0000-0000-000000000000	af76b1d3-21e4-4b4f-88da-b36c4369a49c	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:05:01Z"}	2022-01-13 22:05:01.619497+00
00000000-0000-0000-0000-000000000000	f34e9991-aba6-47d2-bf4a-696bdac5b075	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:05:04Z"}	2022-01-13 22:05:04.049268+00
00000000-0000-0000-0000-000000000000	7c64ab93-9d97-4a5a-9573-f1f2f693a64a	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-13T22:05:10Z"}	2022-01-13 22:05:10.892257+00
00000000-0000-0000-0000-000000000000	a295e44a-8fe4-42fc-ad77-c1b04b953c0b	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-13T23:04:17Z"}	2022-01-13 23:04:17.082795+00
00000000-0000-0000-0000-000000000000	bc929e3d-4c02-41f8-be09-83c1b142b72d	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-13T23:04:17Z"}	2022-01-13 23:04:17.086277+00
00000000-0000-0000-0000-000000000000	6b555427-6c0d-4b74-a3cf-a37c00cfdcf9	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-14T00:24:02Z"}	2022-01-14 00:24:02.810008+00
00000000-0000-0000-0000-000000000000	335df14a-f126-40e4-aa99-3c8cf1876a38	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-14T00:24:02Z"}	2022-01-14 00:24:02.815662+00
00000000-0000-0000-0000-000000000000	a7759955-896a-4a37-a2f0-dc80eb1d5099	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-14T01:23:06Z"}	2022-01-14 01:23:06.640288+00
00000000-0000-0000-0000-000000000000	f96e8a38-d195-45ca-9505-e809f8861310	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-14T01:23:06Z"}	2022-01-14 01:23:06.645704+00
00000000-0000-0000-0000-000000000000	484b4ca8-da8e-4c3a-861e-996e72d6fb81	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-14T02:30:12Z"}	2022-01-14 02:30:12.76393+00
00000000-0000-0000-0000-000000000000	4af27688-3877-4b63-a64c-8ba07fbf9481	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-14T02:30:12Z"}	2022-01-14 02:30:12.767586+00
00000000-0000-0000-0000-000000000000	b2900c58-9802-4ab9-af7c-b8eeb10cb481	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-14T03:30:27Z"}	2022-01-14 03:30:27.354233+00
00000000-0000-0000-0000-000000000000	72caabc6-4001-4f57-bd7a-764983985247	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-14T03:30:27Z"}	2022-01-14 03:30:27.361253+00
00000000-0000-0000-0000-000000000000	9d58b514-c478-486e-93cd-bba29013468c	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T04:18:31Z"}	2022-01-14 04:18:31.534335+00
00000000-0000-0000-0000-000000000000	c73fea57-fdba-4391-b8dc-1717d6a01d7c	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T04:18:33Z"}	2022-01-14 04:18:33.088815+00
00000000-0000-0000-0000-000000000000	5324c417-34ff-4d46-9bbe-7e350baa2996	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T04:26:47Z"}	2022-01-14 04:26:47.512095+00
00000000-0000-0000-0000-000000000000	c95bcfd5-ede1-4120-8278-7760f223a67d	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T04:26:48Z"}	2022-01-14 04:26:48.795283+00
00000000-0000-0000-0000-000000000000	5ad0e5f3-b113-4b62-8825-849a947c4ae6	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-14T15:32:45Z"}	2022-01-14 15:32:45.180277+00
00000000-0000-0000-0000-000000000000	0583d846-e861-4590-9c57-547ca40bfcca	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-14T15:32:45Z"}	2022-01-14 15:32:45.186597+00
00000000-0000-0000-0000-000000000000	8fc869f2-e248-4437-9eb7-196c110ba1ae	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T15:34:24Z"}	2022-01-14 15:34:24.945348+00
00000000-0000-0000-0000-000000000000	d01df850-a849-4de7-ab23-7674dace6a5d	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T15:37:56Z"}	2022-01-14 15:37:56.928553+00
00000000-0000-0000-0000-000000000000	b06765d6-62a1-47e9-8852-852b85322b56	{"action":"user_signedup","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"team","timestamp":"2022-01-14T15:38:11Z"}	2022-01-14 15:38:11.270173+00
00000000-0000-0000-0000-000000000000	451830ab-5f9b-4c73-81e2-a5bef8d1ce37	{"action":"login","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-14T15:38:11Z"}	2022-01-14 15:38:11.277939+00
00000000-0000-0000-0000-000000000000	54858f5f-0c65-4b91-96a4-9935668c76ca	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T16:09:22Z"}	2022-01-14 16:09:22.190883+00
00000000-0000-0000-0000-000000000000	2d9f8b66-7ca5-4327-82fd-072fc3c069c5	{"action":"logout","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-14T16:09:20Z"}	2022-01-14 16:09:20.701658+00
00000000-0000-0000-0000-000000000000	df6f21e4-1e1d-4bc3-9f54-bef77771e48e	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T16:17:40Z"}	2022-01-14 16:17:40.440769+00
00000000-0000-0000-0000-000000000000	d1acbd5d-c5c9-40d3-8eea-9fd16480fc83	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T16:17:41Z"}	2022-01-14 16:17:41.632005+00
00000000-0000-0000-0000-000000000000	59641126-b318-426f-9a65-cd4bdae99a95	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T19:17:27Z"}	2022-01-14 19:17:27.371689+00
00000000-0000-0000-0000-000000000000	ddc19a9d-99cc-4945-9801-cdeffccecf49	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T19:18:48Z"}	2022-01-14 19:18:48.016397+00
00000000-0000-0000-0000-000000000000	ce1a0d83-9053-445c-996e-7ddf5b1fefe9	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T19:18:49Z"}	2022-01-14 19:18:49.190983+00
00000000-0000-0000-0000-000000000000	d7ce97f6-1f5f-4771-8e2c-ebd767603310	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T19:19:16Z"}	2022-01-14 19:19:16.687838+00
00000000-0000-0000-0000-000000000000	b7b73e08-c984-4ba4-9ad2-69131ba691d9	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T19:19:17Z"}	2022-01-14 19:19:17.89337+00
00000000-0000-0000-0000-000000000000	62d475fd-ccde-4f47-be74-9a650024d54e	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T19:58:20Z"}	2022-01-14 19:58:20.147605+00
00000000-0000-0000-0000-000000000000	db9ade69-6019-4fb2-a725-2a01d05ad974	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-14T19:58:21Z"}	2022-01-14 19:58:21.206567+00
00000000-0000-0000-0000-000000000000	12f88f9c-8131-45ba-831d-501fb99ac31b	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-17T21:38:59Z"}	2022-01-17 21:38:59.670003+00
00000000-0000-0000-0000-000000000000	4d3fc733-3abe-4643-948c-ea5b0114b1e4	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-17T21:40:21Z"}	2022-01-17 21:40:21.978294+00
00000000-0000-0000-0000-000000000000	1db95941-1f23-4c1d-802b-3d5b8a319349	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-17T21:40:26Z"}	2022-01-17 21:40:26.665212+00
00000000-0000-0000-0000-000000000000	842e2c07-c30a-4343-9a2c-f58a1f1c6a46	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-17T23:08:13Z"}	2022-01-17 23:08:13.441723+00
00000000-0000-0000-0000-000000000000	5a1a3260-eae5-4d96-87c7-6047a6bad63e	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-17T23:08:13Z"}	2022-01-17 23:08:13.441249+00
00000000-0000-0000-0000-000000000000	fb9d5423-6346-4ad0-a441-be77eb57f319	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-17T23:08:13Z"}	2022-01-17 23:08:13.470001+00
00000000-0000-0000-0000-000000000000	58b35fad-0774-4325-b596-99f8542c392d	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-17T23:08:13Z"}	2022-01-17 23:08:13.470229+00
00000000-0000-0000-0000-000000000000	6e7e796e-9238-433a-8859-9fdd25178dc8	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-18T14:52:57Z"}	2022-01-18 14:52:57.916968+00
00000000-0000-0000-0000-000000000000	55a42c33-360b-4a3b-a1a7-f9185a2c2470	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-18T14:53:06Z"}	2022-01-18 14:53:06.289689+00
00000000-0000-0000-0000-000000000000	dfe7a669-49b2-48b6-8c08-03d640d70dc3	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-18T15:14:08Z"}	2022-01-18 15:14:08.171955+00
00000000-0000-0000-0000-000000000000	fcb43a87-1bd3-4629-b366-9e2e7d30d35f	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-18T15:16:55Z"}	2022-01-18 15:16:55.467514+00
00000000-0000-0000-0000-000000000000	d6c51c77-f8d6-42b5-9002-cf5fe56b4c63	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-18T15:17:39Z"}	2022-01-18 15:17:39.560989+00
00000000-0000-0000-0000-000000000000	6477d78a-18b9-437d-92e8-dc40f7656244	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-18T15:17:42Z"}	2022-01-18 15:17:42.621918+00
00000000-0000-0000-0000-000000000000	09042a30-1ba8-4da3-9676-ac402989d43e	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-18T20:52:05Z"}	2022-01-18 20:52:05.942022+00
00000000-0000-0000-0000-000000000000	58084670-4d68-4748-b61c-205dc3628efa	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-19T03:14:56Z"}	2022-01-19 03:14:56.904467+00
00000000-0000-0000-0000-000000000000	0e2749a5-ae18-4252-bb97-017976423577	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-19T03:14:56Z"}	2022-01-19 03:14:56.92452+00
00000000-0000-0000-0000-000000000000	2cea77b8-cbe1-4d0c-ab3c-a1b0975c2bda	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-19T04:32:40Z"}	2022-01-19 04:32:40.20944+00
00000000-0000-0000-0000-000000000000	de8bc575-17ac-48b9-998e-e96d27356c17	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-19T04:32:40Z"}	2022-01-19 04:32:40.222977+00
00000000-0000-0000-0000-000000000000	d968bcc5-1a2a-4868-b5e6-b4ec6a59c6b2	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-19T14:55:46Z"}	2022-01-19 14:55:46.089402+00
00000000-0000-0000-0000-000000000000	70a17da8-6c9d-4872-ac68-d10e3c3d2c33	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-19T14:55:46Z"}	2022-01-19 14:55:46.098361+00
00000000-0000-0000-0000-000000000000	9e67edcc-be5a-4238-b1fc-de2127ca3ba2	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-19T14:55:47Z"}	2022-01-19 14:55:47.813759+00
00000000-0000-0000-0000-000000000000	a636ff79-a7ee-48aa-81ac-78dbb3ce0102	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-19T14:56:02Z"}	2022-01-19 14:56:02.60387+00
00000000-0000-0000-0000-000000000000	10328f80-3bc3-4a94-a9f1-37b5f6063537	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-19T15:41:34Z"}	2022-01-19 15:41:34.627115+00
00000000-0000-0000-0000-000000000000	0ac85ebf-842d-4846-8206-00f7e3e90638	{"action":"login","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-19T15:41:46Z"}	2022-01-19 15:41:46.482547+00
00000000-0000-0000-0000-000000000000	2aa931be-9ccc-475a-b205-1b4009412cd8	{"action":"token_refreshed","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"token","timestamp":"2022-01-19T21:51:18Z"}	2022-01-19 21:51:18.474574+00
00000000-0000-0000-0000-000000000000	3ec7ae60-46a7-4ca5-b5bb-837fcb297c90	{"action":"token_revoked","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"token","timestamp":"2022-01-19T21:51:18Z"}	2022-01-19 21:51:18.54409+00
00000000-0000-0000-0000-000000000000	72df6e46-10cf-4c98-bc9d-2dd48e2ff752	{"action":"logout","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-19T22:24:25Z"}	2022-01-19 22:24:25.431178+00
00000000-0000-0000-0000-000000000000	dbc965f2-a4f2-4c64-ae29-79422d2c40a1	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-19T22:24:29Z"}	2022-01-19 22:24:29.544346+00
00000000-0000-0000-0000-000000000000	36f2e3ce-d8de-48ac-ae17-3b85b2cc0744	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-19T23:23:33Z"}	2022-01-19 23:23:33.128932+00
00000000-0000-0000-0000-000000000000	76d1b356-40f2-40c1-a722-504c84c60601	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-19T23:23:33Z"}	2022-01-19 23:23:33.134149+00
00000000-0000-0000-0000-000000000000	1504b5d8-724c-423c-89db-82fd73719841	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-20T00:32:49Z"}	2022-01-20 00:32:49.413228+00
00000000-0000-0000-0000-000000000000	e88d38ac-584e-45d3-b4ee-2c0cdb7f080a	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-20T00:32:49Z"}	2022-01-20 00:32:49.418089+00
00000000-0000-0000-0000-000000000000	d26e447b-fd59-4eaf-b8a3-1c75033e876b	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-20T01:31:53Z"}	2022-01-20 01:31:53.776366+00
00000000-0000-0000-0000-000000000000	d95c2943-e8e4-4276-ab81-6201ab252f18	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-20T01:31:53Z"}	2022-01-20 01:31:53.780196+00
00000000-0000-0000-0000-000000000000	1d2d9efd-51b7-4aa1-931f-22c833a485ff	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-20T04:32:15Z"}	2022-01-20 04:32:15.842037+00
00000000-0000-0000-0000-000000000000	e170d2d3-bbc7-4e31-ac78-29ac686492f7	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-20T04:32:15Z"}	2022-01-20 04:32:15.888514+00
00000000-0000-0000-0000-000000000000	81379333-f4c7-42bd-86c6-9cc1d1a38400	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-20T15:24:14Z"}	2022-01-20 15:24:14.837689+00
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) FROM stdin;
48c92525-ec52-4601-a373-677f38d67011	48c92525-ec52-4601-a373-677f38d67011	{"sub": "48c92525-ec52-4601-a373-677f38d67011"}	email	2022-01-13 22:01:28.771399+00	2022-01-13 22:01:28.771754+00	2022-01-13 22:01:28.771754+00
4975184a-4093-4e63-882a-2c2f3b2405e0	4975184a-4093-4e63-882a-2c2f3b2405e0	{"sub": "4975184a-4093-4e63-882a-2c2f3b2405e0"}	email	2022-01-14 15:38:11.264985+00	2022-01-14 15:38:11.265354+00	2022-01-14 15:38:11.265354+00
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent) FROM stdin;
00000000-0000-0000-0000-000000000000	39	NVXepqGBriSQSPfj94Mlmw	48c92525-ec52-4601-a373-677f38d67011	t	2022-01-19 22:24:29.549396+00	2022-01-19 22:24:29.549396+00	\N
00000000-0000-0000-0000-000000000000	40	pEFCkjb3YZf2muGudIPXkg	48c92525-ec52-4601-a373-677f38d67011	t	2022-01-19 23:23:33.136986+00	2022-01-19 23:23:33.136986+00	NVXepqGBriSQSPfj94Mlmw
00000000-0000-0000-0000-000000000000	41	vvueuzI5ePiuXwa6KLN8cg	48c92525-ec52-4601-a373-677f38d67011	t	2022-01-20 00:32:49.421756+00	2022-01-20 00:32:49.421756+00	pEFCkjb3YZf2muGudIPXkg
00000000-0000-0000-0000-000000000000	42	rML0c9PTHTxzTrowogJnOg	48c92525-ec52-4601-a373-677f38d67011	t	2022-01-20 01:31:53.783363+00	2022-01-20 01:31:53.783363+00	vvueuzI5ePiuXwa6KLN8cg
00000000-0000-0000-0000-000000000000	43	g0NCsxdf3c4BR9OefjRiYA	48c92525-ec52-4601-a373-677f38d67011	f	2022-01-20 04:32:15.925654+00	2022-01-20 04:32:15.925654+00	rML0c9PTHTxzTrowogJnOg
00000000-0000-0000-0000-000000000000	44	LdXGXTC27SdWj87J2aDfEg	48c92525-ec52-4601-a373-677f38d67011	f	2022-01-20 15:24:14.84138+00	2022-01-20 15:24:14.84138+00	\N
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status) FROM stdin;
00000000-0000-0000-0000-000000000000	4975184a-4093-4e63-882a-2c2f3b2405e0		authenticated	austin.malerba@gmail.com	$2a$10$WhRyrT4X.U8REHoAoDV2Iuzvvy88/YIiSA5x60Prl62D9oHwEX1oi	2022-01-14 15:38:11.272417+00	\N		\N		\N			\N	2022-01-19 15:41:46.484653+00	{"provider": "email", "providers": ["email"]}	{"avatar": "https://picsum.photos/id/237/200/300", "user_name": "austin.malerba", "avatar_url": "https://picsum.photos/id/237/200/300"}	f	2022-01-14 15:38:11.245611+00	2022-01-14 15:38:11.245611+00	\N	\N			\N		0
00000000-0000-0000-0000-000000000000	48c92525-ec52-4601-a373-677f38d67011		authenticated	malerba118@gmail.com	$2a$10$bUgcz0RemIQGMkyzEV/ycOl9tLJQawXaOnpmXJjatjeQcpPUa.FXy	2022-01-13 22:01:28.785305+00	\N		\N		\N			\N	2022-01-20 15:24:14.841122+00	{"provider": "email", "providers": ["email"]}	{"user_name": "malerba118", "avatar_url": "https://picsum.photos/id/250/200/300"}	f	2022-01-13 22:01:28.737025+00	2022-01-13 22:01:28.737025+00	\N	\N			\N		0
\.


--
-- Data for Name: comment_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comment_reactions (id, created_at, comment_id, user_id, reaction_type) FROM stdin;
aa68b9cd-2e35-4b2b-a42b-3da17b2781d6	2022-01-17 23:44:29.926956+00	8254ff03-c264-4c10-bf23-4170a931059a	48c92525-ec52-4601-a373-677f38d67011	smile
194b9cb1-9650-40ea-b06d-c34120ba4e1c	2022-01-18 21:18:21.778618+00	ae7a590c-ece8-40ce-b9d5-53679b19f650	48c92525-ec52-4601-a373-677f38d67011	heart
58318c7e-8b23-4cc4-8af8-843b7a2f5152	2022-01-18 21:28:12.602081+00	008be586-cd7f-4d4a-9b54-abacb2661c05	48c92525-ec52-4601-a373-677f38d67011	smile
6a7a800a-f1e5-4024-87be-499c74e8f9df	2022-01-19 03:29:51.641799+00	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	48c92525-ec52-4601-a373-677f38d67011	heart
1eeb9833-7fef-441d-b352-f971c28afcf4	2022-01-19 15:27:34.858052+00	7ac59506-55bf-4475-90f9-b64ecd193e8f	48c92525-ec52-4601-a373-677f38d67011	heart
8319afba-381f-4888-a2c2-038152209448	2022-01-19 21:52:23.698519+00	7ac59506-55bf-4475-90f9-b64ecd193e8f	4975184a-4093-4e63-882a-2c2f3b2405e0	heart
b990808c-8828-4d4e-b1d4-52e68632dbb5	2022-01-19 22:01:42.839225+00	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	4975184a-4093-4e63-882a-2c2f3b2405e0	heart
bbe25921-5a79-4306-ad61-b682834039f2	2022-01-19 23:45:13.881119+00	a0b5fe1b-52a6-4e50-9521-03a5245ef85d	48c92525-ec52-4601-a373-677f38d67011	heart
a34c5633-795c-4786-a75d-f7fbc126b770	2022-01-19 23:45:21.889526+00	0a059a7e-e4d4-4d1f-88fa-b1d02e52a0e4	48c92525-ec52-4601-a373-677f38d67011	heart
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments (id, created_at, topic, comment, user_id, parent_id, mentioned_user_ids) FROM stdin;
c7010b1c-0db0-4845-b702-9e94c45309a4	2022-01-14 02:12:49+00	tutorial-one	test comment one	48c92525-ec52-4601-a373-677f38d67011	\N	{}
cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	2022-01-14 02:14:39+00	tutorial-one	test comment 2	48c92525-ec52-4601-a373-677f38d67011	\N	{}
8254ff03-c264-4c10-bf23-4170a931059a	2022-01-14 02:15:31+00	tutorial-one	test reply one	48c92525-ec52-4601-a373-677f38d67011	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	{}
4d750c6c-05b5-4910-bac0-af3b7b1ef83c	2022-01-14 02:16:50+00	tutorial-one	test reply two	48c92525-ec52-4601-a373-677f38d67011	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	{}
69156340-0ade-47bc-8283-abddeed430c7	2022-01-17 23:42:21.7108+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="4975184a-4093-4e63-882a-2c2f3b2405e0" data-label="austin.malerba">@austin.malerba</span> hi</p>	48c92525-ec52-4601-a373-677f38d67011	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	{}
cf52d694-6725-4dd8-83b6-1362a7c60ae1	2022-01-18 15:17:56.012+00	tutorial-one	<p>test</p>	48c92525-ec52-4601-a373-677f38d67011	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	{}
ae7a590c-ece8-40ce-b9d5-53679b19f650	2022-01-18 21:14:56.684593+00	tutorial-one	<p>blahhhh</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
66cca2a5-35d1-4529-8d5f-5a0bbfa378f9	2022-01-18 21:15:08.404316+00	tutorial-one	<p>sdggdfg</p>	48c92525-ec52-4601-a373-677f38d67011	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	{}
008be586-cd7f-4d4a-9b54-abacb2661c05	2022-01-18 21:15:10.82533+00	tutorial-one	<p>foooooooooooo</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
e4b1b41e-9117-40f8-ae4d-d040573ee7d0	2022-01-18 21:27:55.249388+00	tutorial-one	<p>test</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
1d976d4a-d5cd-4f55-9f0c-524737502a0e	2022-01-18 21:27:58.279943+00	tutorial-one	<p>teeef</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
d38e2f81-c365-4eb7-9313-401a7d41309d	2022-01-18 21:28:04.367949+00	tutorial-one	<p>sdfsf</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
0a44e7f4-c92b-4f5f-8f7e-465a2a6bf13d	2022-01-18 21:28:24.690564+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="48c92525-ec52-4601-a373-677f38d67011" data-label="malerba118">@malerba118</span> sdasg</p>	48c92525-ec52-4601-a373-677f38d67011	d38e2f81-c365-4eb7-9313-401a7d41309d	{}
8411f23b-dfb3-4ddc-99ce-6e4fa6b2cf83	2022-01-19 03:29:56.178896+00	tutorial-one	<p>dsfd</p>	48c92525-ec52-4601-a373-677f38d67011	e4b1b41e-9117-40f8-ae4d-d040573ee7d0	{}
016d8823-9d4b-455f-b320-0fa6b7c78cbe	2022-01-19 03:44:21.147686+00	tutorial-one	malerba118	48c92525-ec52-4601-a373-677f38d67011	ae7a590c-ece8-40ce-b9d5-53679b19f650	{}
e58c4aa7-c37f-44b5-8767-f64724068092	2022-01-19 04:32:51.169392+00	tutorial-one	<p>test</p>	48c92525-ec52-4601-a373-677f38d67011	d38e2f81-c365-4eb7-9313-401a7d41309d	{}
f4c71d75-c96c-4cfc-ae2b-83fb27f3790f	2022-01-19 05:01:26.176983+00	tutorial-one	<p>dg</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
7ac59506-55bf-4475-90f9-b64ecd193e8f	2022-01-19 05:01:29.457285+00	tutorial-one	<p>dfg</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
c20cee1a-b69b-4a79-a320-ef912f9b57e7	2022-01-19 15:27:50.502735+00	tutorial-one	<p>malerba118 yass</p>	48c92525-ec52-4601-a373-677f38d67011	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	{}
ed50b431-51b6-4bbc-81f2-886919f6a273	2022-01-19 15:40:51.813964+00	tutorial-one	<p>fooo</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
1a02661f-9932-42eb-a133-9a1d2dbc72b2	2022-01-19 15:41:59.393165+00	tutorial-one	<p>hello</p>	4975184a-4093-4e63-882a-2c2f3b2405e0	ae7a590c-ece8-40ce-b9d5-53679b19f650	{}
be172029-e723-4821-8cc2-7f07d94f7d70	2022-01-19 15:42:12.317193+00	tutorial-one	<p>testtt</p>	4975184a-4093-4e63-882a-2c2f3b2405e0	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	{}
3db24809-be08-4a33-b116-1cde14ff6a58	2022-01-19 15:42:17.964988+00	tutorial-one	<p>sdgsdfggdfs</p>	4975184a-4093-4e63-882a-2c2f3b2405e0	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	{}
965cf2c4-3fa2-44b9-8910-496b34ce4376	2022-01-19 15:43:36.949746+00	tutorial-one	<p>sfdsg dsfgdfsg</p><p></p><p>sfdsg dsfgdfsg<br>sfdsg dsfgdfsg<br>sfdsg dsfgdfsgsfdsg dsfgdfsg</p>	4975184a-4093-4e63-882a-2c2f3b2405e0	cdfbff68-c9ea-4ed6-b922-0be8e651bcb5	{}
b59e0e4e-03f1-40b5-9da3-e02b285ca0e3	2022-01-19 22:03:07.94824+00	tutorial-one		4975184a-4093-4e63-882a-2c2f3b2405e0	\N	{}
89e4cb16-a85b-4ea7-969a-24d5ba213a5b	2022-01-19 22:17:16.603897+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="4975184a-4093-4e63-882a-2c2f3b2405e0" data-label="austin.malerba">@austin.malerba</span> </p>	4975184a-4093-4e63-882a-2c2f3b2405e0	\N	{}
6c08ed50-a089-4ca1-b35f-14eb9469f122	2022-01-19 22:21:24.760269+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="48c92525-ec52-4601-a373-677f38d67011" data-label="malerba118">@malerba118</span> fsdfadsf</p>	4975184a-4093-4e63-882a-2c2f3b2405e0	c7010b1c-0db0-4845-b702-9e94c45309a4	{}
7234a0da-2936-4410-9887-5aff6b62f2ec	2022-01-19 22:21:40.78363+00	tutorial-one	<p>sdgdfgdg</p>	4975184a-4093-4e63-882a-2c2f3b2405e0	c7010b1c-0db0-4845-b702-9e94c45309a4	{}
e34b0b39-9d09-425e-a090-30dbc8ba0e56	2022-01-19 22:22:40.467223+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="48c92525-ec52-4601-a373-677f38d67011" data-label="malerba118">@malerba118</span> fgasg</p>	4975184a-4093-4e63-882a-2c2f3b2405e0	c7010b1c-0db0-4845-b702-9e94c45309a4	{}
92288012-35e0-43fd-9197-6bffab0797ec	2022-01-19 22:23:40.696443+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="48c92525-ec52-4601-a373-677f38d67011" data-label="malerba118">@malerba118</span> sdfsfd</p>	4975184a-4093-4e63-882a-2c2f3b2405e0	c7010b1c-0db0-4845-b702-9e94c45309a4	{}
56ad57e2-6ed3-43aa-89a8-e73bd9f9d7b3	2022-01-19 22:32:47.278095+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="4975184a-4093-4e63-882a-2c2f3b2405e0" data-label="austin.malerba">@austin.malerba</span> ds</p>	48c92525-ec52-4601-a373-677f38d67011	c7010b1c-0db0-4845-b702-9e94c45309a4	{}
9a59d0dd-ee7e-4c92-941f-539cb4a6004f	2022-01-19 22:36:13.606518+00	tutorial-one	<p>dfgdssdfgdfg</p><p></p><p></p><p>dsfgdsfg</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
0ba87687-cbca-4002-ae7a-bcc1bf267fdb	2022-01-19 22:36:26.050569+00	tutorial-one	<p>dfsgg</p><p>dfgdsfg</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
a0b5fe1b-52a6-4e50-9521-03a5245ef85d	2022-01-19 22:38:00.28031+00	tutorial-one	<p>dfgdsfg</p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
8620e578-4501-408d-8d60-8a6ca0d1d726	2022-01-19 22:38:12.164123+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="48c92525-ec52-4601-a373-677f38d67011" data-label="malerba118">@malerba118</span> dsfgdsfg</p>	48c92525-ec52-4601-a373-677f38d67011	0ba87687-cbca-4002-ae7a-bcc1bf267fdb	{}
1ab499a5-5df0-4c09-9512-f3037c8b90f2	2022-01-19 23:09:15.841863+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="4975184a-4093-4e63-882a-2c2f3b2405e0" data-label="austin.malerba">@austin.malerba</span>  dgdg <span data-type="mention" class="mention" data-id="48c92525-ec52-4601-a373-677f38d67011" data-label="malerba118">@malerba118</span> </p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
cdb9a728-7285-4a84-84e1-cd7e1d3c7b98	2022-01-19 23:25:55.887464+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="4975184a-4093-4e63-882a-2c2f3b2405e0" data-label="austin.malerba">@austin.malerba</span> </p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
4b2d041c-b1b9-4d2d-805e-fb80d4df08ba	2022-01-19 23:33:33.456468+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="48c92525-ec52-4601-a373-677f38d67011" data-label="malerba118">@malerba118</span> </p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
97c29e87-004f-43e6-bf4f-54d5d7324659	2022-01-19 23:36:29.048871+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="4975184a-4093-4e63-882a-2c2f3b2405e0" data-label="austin.malerba">@austin.malerba</span> </p>	48c92525-ec52-4601-a373-677f38d67011	\N	{}
a6caa97a-0639-4279-a6c8-5c9f1a8f9979	2022-01-19 23:39:05.536282+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="48c92525-ec52-4601-a373-677f38d67011" data-label="malerba118">@malerba118</span>  sdfsffd <span data-type="mention" class="mention" data-id="4975184a-4093-4e63-882a-2c2f3b2405e0" data-label="austin.malerba">@austin.malerba</span> </p>	48c92525-ec52-4601-a373-677f38d67011	\N	{48c92525-ec52-4601-a373-677f38d67011,4975184a-4093-4e63-882a-2c2f3b2405e0}
f4ed9b7f-8bb1-4255-88b0-165455757cb0	2022-01-19 23:41:28.806499+00	tutorial-one	<p>foo <span data-type="mention" class="mention" data-id="48c92525-ec52-4601-a373-677f38d67011" data-label="malerba118">@malerba118</span> </p>	48c92525-ec52-4601-a373-677f38d67011	\N	{48c92525-ec52-4601-a373-677f38d67011}
0a059a7e-e4d4-4d1f-88fa-b1d02e52a0e4	2022-01-19 23:41:37.457246+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="48c92525-ec52-4601-a373-677f38d67011" data-label="malerba118">@malerba118</span> sfg</p>	48c92525-ec52-4601-a373-677f38d67011	f4ed9b7f-8bb1-4255-88b0-165455757cb0	{48c92525-ec52-4601-a373-677f38d67011}
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profiles (id, created_at, name, avatar) FROM stdin;
4975184a-4093-4e63-882a-2c2f3b2405e0	2022-01-14 20:19:33+00	austin.malerba	\N
48c92525-ec52-4601-a373-677f38d67011	2022-01-14 20:20:08+00	malerba118	\N
\.


--
-- Data for Name: reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reactions (type, created_at, metadata) FROM stdin;
heart	2022-01-14 15:05:34+00	{"url": "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGNsYXNzPSJoLTYgdy02IiBmaWxsPSJub25lIiB2aWV3Qm94PSIwIDAgMjQgMjQiIHN0cm9rZT0iY3VycmVudENvbG9yIj4KICA8cGF0aCBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIHN0cm9rZS13aWR0aD0iMiIgZD0iTTQuMzE4IDYuMzE4YTQuNSA0LjUgMCAwMDAgNi4zNjRMMTIgMjAuMzY0bDcuNjgyLTcuNjgyYTQuNSA0LjUgMCAwMC02LjM2NC02LjM2NEwxMiA3LjYzNmwtMS4zMTgtMS4zMThhNC41IDQuNSAwIDAwLTYuMzY0IDB6IiAvPgo8L3N2Zz4=", "label": "Heart"}
smile	2022-01-14 15:05:45+00	{"url": "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGNsYXNzPSJoLTYgdy02IiBmaWxsPSJub25lIiB2aWV3Qm94PSIwIDAgMjQgMjQiIHN0cm9rZT0iY3VycmVudENvbG9yIj4KICA8cGF0aCBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiIHN0cm9rZS13aWR0aD0iMiIgZD0iTTE0LjgyOCAxNC44MjhhNCA0IDAgMDEtNS42NTYgME05IDEwaC4wMU0xNSAxMGguMDFNMjEgMTJhOSA5IDAgMTEtMTggMCA5IDkgMCAwMTE4IDB6IiAvPgo8L3N2Zz4=", "label": "Smile"}
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: postgres
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2022-01-13 21:53:57
20211116045059	2022-01-13 21:53:57
20211116050929	2022-01-13 21:53:57
20211116051442	2022-01-13 21:53:57
20211116212300	2022-01-13 21:53:57
20211116213355	2022-01-13 21:53:57
20211116213934	2022-01-13 21:53:57
20211116214523	2022-01-13 21:53:57
20211122062447	2022-01-13 21:53:57
20211124070109	2022-01-13 21:53:57
20211202204204	2022-01-13 21:53:57
20211202204605	2022-01-13 21:53:57
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: postgres
--

COPY realtime.subscription (id, user_id, email, entity, filters, created_at) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2022-01-13 21:54:04.515389
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2022-01-13 21:54:04.543727
2	pathtoken-column	49756be03be4c17bb85fe70d4a861f27de7e49ad	2022-01-13 21:54:04.549603
3	add-migrations-rls	bb5d124c53d68635a883e399426c6a5a25fc893d	2022-01-13 21:54:04.614229
4	add-size-functions	6d79007d04f5acd288c9c250c42d2d5fd286c54d	2022-01-13 21:54:04.619659
5	change-column-name-in-get-size	fd65688505d2ffa9fbdc58a944348dd8604d688c	2022-01-13 21:54:04.625994
6	add-rls-to-buckets	63e2bab75a2040fee8e3fb3f15a0d26f3380e9b6	2022-01-13 21:54:04.63308
7	add-public-to-buckets	82568934f8a4d9e0a85f126f6fb483ad8214c418	2022-01-13 21:54:04.640413
8	fix-search-function	1a43a40eddb525f2e2f26efd709e6c06e58e059c	2022-01-13 21:54:04.646192
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 44, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: postgres
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (provider, id);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: comment_reactions comment_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT comment_reactions_pkey PRIMARY KEY (id);


--
-- Name: comment_reactions comment_reactions_user_id_comment_id_reaction_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT comment_reactions_user_id_comment_id_reaction_type_key UNIQUE (user_id, comment_id, reaction_type);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: reactions reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (type);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: postgres
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: postgres
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: subscription subscription_entity_user_id_filters_key; Type: CONSTRAINT; Schema: realtime; Owner: postgres
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT subscription_entity_user_id_filters_key UNIQUE (entity, user_id, filters);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_token_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX refresh_tokens_token_idx ON auth.refresh_tokens USING btree (token);


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, email);


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: supabase_auth_admin
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: postgres
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING hash (entity);


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: supabase_storage_admin
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: postgres
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_parent_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: supabase_auth_admin
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_parent_fkey FOREIGN KEY (parent) REFERENCES auth.refresh_tokens(token);


--
-- Name: comment_reactions comment_reactions_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT comment_reactions_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id);


--
-- Name: comment_reactions comment_reactions_reaction_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT comment_reactions_reaction_type_fkey FOREIGN KEY (reaction_type) REFERENCES public.reactions(type);


--
-- Name: comment_reactions comment_reactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment_reactions
    ADD CONSTRAINT comment_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: comments comments_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.comments(id);


--
-- Name: comments comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id);


--
-- Name: buckets buckets_owner_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_owner_fkey FOREIGN KEY (owner) REFERENCES auth.users(id);


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: objects objects_owner_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_owner_fkey FOREIGN KEY (owner) REFERENCES auth.users(id);


--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: supabase_storage_admin
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: postgres
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


ALTER PUBLICATION supabase_realtime OWNER TO postgres;

--
-- Name: SCHEMA auth; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA auth TO anon;
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA auth TO service_role;
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON SCHEMA auth TO dashboard_user;
GRANT USAGE ON SCHEMA auth TO postgres;


--
-- Name: SCHEMA extensions; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA extensions TO anon;
GRANT USAGE ON SCHEMA extensions TO authenticated;
GRANT USAGE ON SCHEMA extensions TO service_role;
GRANT ALL ON SCHEMA extensions TO dashboard_user;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: SCHEMA realtime; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA realtime TO authenticated;


--
-- Name: SCHEMA storage; Type: ACL; Schema: -; Owner: supabase_admin
--

GRANT USAGE ON SCHEMA storage TO postgres;
GRANT USAGE ON SCHEMA storage TO anon;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT USAGE ON SCHEMA storage TO service_role;
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON SCHEMA storage TO dashboard_user;


--
-- Name: FUNCTION email(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.email() TO dashboard_user;


--
-- Name: FUNCTION role(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.role() TO dashboard_user;


--
-- Name: FUNCTION uid(); Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON FUNCTION auth.uid() TO dashboard_user;


--
-- Name: FUNCTION algorithm_sign(signables text, secret text, algorithm text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.algorithm_sign(signables text, secret text, algorithm text) TO dashboard_user;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.armor(bytea) TO dashboard_user;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.armor(bytea, text[], text[]) TO dashboard_user;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.crypt(text, text) TO dashboard_user;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.dearmor(text) TO dashboard_user;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.decrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.digest(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.digest(text, text) TO dashboard_user;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.encrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.gen_random_bytes(integer) TO dashboard_user;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.gen_random_uuid() TO dashboard_user;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.gen_salt(text) TO dashboard_user;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.gen_salt(text, integer) TO dashboard_user;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.grant_pg_cron_access() TO dashboard_user;


--
-- Name: FUNCTION grant_pg_net_access(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.grant_pg_net_access() TO dashboard_user;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.hmac(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.hmac(text, text, text) TO dashboard_user;


--
-- Name: FUNCTION notify_api_restart(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.notify_api_restart() TO dashboard_user;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO dashboard_user;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_key_id(bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION sign(payload json, secret text, algorithm text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.sign(payload json, secret text, algorithm text) TO dashboard_user;


--
-- Name: FUNCTION try_cast_double(inp text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.try_cast_double(inp text) TO dashboard_user;


--
-- Name: FUNCTION url_decode(data text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.url_decode(data text) TO dashboard_user;


--
-- Name: FUNCTION url_encode(data bytea); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.url_encode(data bytea) TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v1(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v1() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v1mc(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v1mc() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v3(namespace uuid, name text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v4(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v4() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v5(namespace uuid, name text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO dashboard_user;


--
-- Name: FUNCTION uuid_nil(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.uuid_nil() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_dns(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.uuid_ns_dns() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_oid(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.uuid_ns_oid() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_url(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.uuid_ns_url() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_x500(); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.uuid_ns_x500() TO dashboard_user;


--
-- Name: FUNCTION verify(token text, secret text, algorithm text); Type: ACL; Schema: extensions; Owner: postgres
--

GRANT ALL ON FUNCTION extensions.verify(token text, secret text, algorithm text) TO dashboard_user;


--
-- Name: FUNCTION pgrst_watch(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgrst_watch() TO anon;
GRANT ALL ON FUNCTION public.pgrst_watch() TO authenticated;
GRANT ALL ON FUNCTION public.pgrst_watch() TO service_role;


--
-- Name: FUNCTION extension(name text); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.extension(name text) TO anon;
GRANT ALL ON FUNCTION storage.extension(name text) TO authenticated;
GRANT ALL ON FUNCTION storage.extension(name text) TO service_role;
GRANT ALL ON FUNCTION storage.extension(name text) TO dashboard_user;


--
-- Name: FUNCTION filename(name text); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.filename(name text) TO anon;
GRANT ALL ON FUNCTION storage.filename(name text) TO authenticated;
GRANT ALL ON FUNCTION storage.filename(name text) TO service_role;
GRANT ALL ON FUNCTION storage.filename(name text) TO dashboard_user;


--
-- Name: FUNCTION foldername(name text); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.foldername(name text) TO anon;
GRANT ALL ON FUNCTION storage.foldername(name text) TO authenticated;
GRANT ALL ON FUNCTION storage.foldername(name text) TO service_role;
GRANT ALL ON FUNCTION storage.foldername(name text) TO dashboard_user;


--
-- Name: FUNCTION search(prefix text, bucketname text, limits integer, levels integer, offsets integer); Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON FUNCTION storage.search(prefix text, bucketname text, limits integer, levels integer, offsets integer) TO anon;
GRANT ALL ON FUNCTION storage.search(prefix text, bucketname text, limits integer, levels integer, offsets integer) TO authenticated;
GRANT ALL ON FUNCTION storage.search(prefix text, bucketname text, limits integer, levels integer, offsets integer) TO service_role;
GRANT ALL ON FUNCTION storage.search(prefix text, bucketname text, limits integer, levels integer, offsets integer) TO dashboard_user;


--
-- Name: TABLE audit_log_entries; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.audit_log_entries TO dashboard_user;
GRANT ALL ON TABLE auth.audit_log_entries TO postgres;


--
-- Name: TABLE identities; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.identities TO postgres;
GRANT ALL ON TABLE auth.identities TO dashboard_user;


--
-- Name: TABLE instances; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.instances TO dashboard_user;
GRANT ALL ON TABLE auth.instances TO postgres;


--
-- Name: TABLE refresh_tokens; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.refresh_tokens TO dashboard_user;
GRANT ALL ON TABLE auth.refresh_tokens TO postgres;


--
-- Name: SEQUENCE refresh_tokens_id_seq; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON SEQUENCE auth.refresh_tokens_id_seq TO dashboard_user;
GRANT ALL ON SEQUENCE auth.refresh_tokens_id_seq TO postgres;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.schema_migrations TO dashboard_user;
GRANT ALL ON TABLE auth.schema_migrations TO postgres;


--
-- Name: TABLE users; Type: ACL; Schema: auth; Owner: supabase_auth_admin
--

GRANT ALL ON TABLE auth.users TO dashboard_user;
GRANT ALL ON TABLE auth.users TO postgres;


--
-- Name: TABLE comment_reactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.comment_reactions TO anon;
GRANT ALL ON TABLE public.comment_reactions TO authenticated;
GRANT ALL ON TABLE public.comment_reactions TO service_role;


--
-- Name: TABLE comment_reactions_metadata; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.comment_reactions_metadata TO anon;
GRANT ALL ON TABLE public.comment_reactions_metadata TO authenticated;
GRANT ALL ON TABLE public.comment_reactions_metadata TO service_role;


--
-- Name: TABLE comment_reactions_metadata_two; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.comment_reactions_metadata_two TO anon;
GRANT ALL ON TABLE public.comment_reactions_metadata_two TO authenticated;
GRANT ALL ON TABLE public.comment_reactions_metadata_two TO service_role;


--
-- Name: TABLE comments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.comments TO anon;
GRANT ALL ON TABLE public.comments TO authenticated;
GRANT ALL ON TABLE public.comments TO service_role;


--
-- Name: TABLE comments_with_metadata; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.comments_with_metadata TO anon;
GRANT ALL ON TABLE public.comments_with_metadata TO authenticated;
GRANT ALL ON TABLE public.comments_with_metadata TO service_role;


--
-- Name: TABLE display_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.display_users TO anon;
GRANT ALL ON TABLE public.display_users TO authenticated;
GRANT ALL ON TABLE public.display_users TO service_role;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profiles TO anon;
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT ALL ON TABLE public.profiles TO service_role;


--
-- Name: TABLE reactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.reactions TO anon;
GRANT ALL ON TABLE public.reactions TO authenticated;
GRANT ALL ON TABLE public.reactions TO service_role;


--
-- Name: TABLE buckets; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.buckets TO anon;
GRANT ALL ON TABLE storage.buckets TO authenticated;
GRANT ALL ON TABLE storage.buckets TO service_role;


--
-- Name: TABLE migrations; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.migrations TO anon;
GRANT ALL ON TABLE storage.migrations TO authenticated;
GRANT ALL ON TABLE storage.migrations TO service_role;


--
-- Name: TABLE objects; Type: ACL; Schema: storage; Owner: supabase_storage_admin
--

GRANT ALL ON TABLE storage.objects TO anon;
GRANT ALL ON TABLE storage.objects TO authenticated;
GRANT ALL ON TABLE storage.objects TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: auth; Owner: supabase_auth_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON TABLES  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON SEQUENCES  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON FUNCTIONS  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: realtime; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON TABLES  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: storage; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES  TO service_role;


--
-- Name: api_restart; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER api_restart ON ddl_command_end
   EXECUTE FUNCTION extensions.notify_api_restart();


ALTER EVENT TRIGGER api_restart OWNER TO postgres;

--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE SCHEMA')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


ALTER EVENT TRIGGER issue_pg_cron_access OWNER TO postgres;

--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


ALTER EVENT TRIGGER issue_pg_net_access OWNER TO postgres;

--
-- Name: pgrst_watch; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER pgrst_watch ON ddl_command_end
   EXECUTE FUNCTION public.pgrst_watch();


ALTER EVENT TRIGGER pgrst_watch OWNER TO postgres;

--
-- PostgreSQL database dump complete
--

