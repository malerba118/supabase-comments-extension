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
  GROUP BY comment_reactions.comment_id, comment_reactions.reaction_type
  ORDER BY comment_reactions.reaction_type;


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
00000000-0000-0000-0000-000000000000	b6686350-f5bd-4b39-bea7-83b5f1f49b3f	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-20T21:21:50Z"}	2022-01-20 21:21:50.61426+00
00000000-0000-0000-0000-000000000000	9d8a464c-564f-47c2-b9fd-6405675fb387	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-20T22:20:51Z"}	2022-01-20 22:20:51.508625+00
00000000-0000-0000-0000-000000000000	7f6a3970-63a3-44cb-8aa3-14cf4fe99c77	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-20T22:20:51Z"}	2022-01-20 22:20:51.514228+00
00000000-0000-0000-0000-000000000000	21ae4a00-462b-48ed-b987-76953b16005d	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T00:05:57Z"}	2022-01-21 00:05:57.679337+00
00000000-0000-0000-0000-000000000000	04caa1dd-8c1a-453b-999f-b0e61469efbd	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T00:05:57Z"}	2022-01-21 00:05:57.683136+00
00000000-0000-0000-0000-000000000000	5b47f3b6-18e1-41fc-9af2-2ac604ea2c57	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T01:04:57Z"}	2022-01-21 01:04:57.858079+00
00000000-0000-0000-0000-000000000000	96dfd7d4-545f-40be-b725-00a4cce8ccef	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T01:04:57Z"}	2022-01-21 01:04:57.862348+00
00000000-0000-0000-0000-000000000000	16f41bc5-a307-4658-a0bd-781b46e47bc5	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-21T01:52:11Z"}	2022-01-21 01:52:11.748838+00
00000000-0000-0000-0000-000000000000	f78a0add-dae6-4523-b603-eb9ef95d1e23	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T02:04:07Z"}	2022-01-21 02:04:07.891432+00
00000000-0000-0000-0000-000000000000	5368d9d7-d465-4f9a-8d77-db59225f580c	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T02:04:07Z"}	2022-01-21 02:04:07.896098+00
00000000-0000-0000-0000-000000000000	22a13e38-7b86-45f7-a4f4-8d2bacdda72f	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T20:25:41Z"}	2022-01-21 20:25:41.91363+00
00000000-0000-0000-0000-000000000000	088de07c-9584-4860-b4c5-63839bc50527	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T20:25:41Z"}	2022-01-21 20:25:41.934635+00
00000000-0000-0000-0000-000000000000	cd628cb2-7989-4cb3-ac75-bfc292598312	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T22:24:01Z"}	2022-01-21 22:24:01.79946+00
00000000-0000-0000-0000-000000000000	28abe424-b805-495e-933f-d39da349ef09	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T22:24:01Z"}	2022-01-21 22:24:01.833545+00
00000000-0000-0000-0000-000000000000	91abb461-5d2a-4a8d-96c9-d4804b53e54b	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T23:30:59Z"}	2022-01-21 23:30:59.864797+00
00000000-0000-0000-0000-000000000000	44e749f0-3154-4c5a-8e55-5828afdc4d94	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-21T23:30:59Z"}	2022-01-21 23:30:59.887973+00
00000000-0000-0000-0000-000000000000	2e7e529d-f25a-49b0-9b61-54f70b3ee94c	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-22T00:43:34Z"}	2022-01-22 00:43:34.487368+00
00000000-0000-0000-0000-000000000000	5c1427f5-77d7-45ef-9602-9b970deb8946	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-22T00:43:34Z"}	2022-01-22 00:43:34.497628+00
00000000-0000-0000-0000-000000000000	153d1694-be01-4652-8af8-3b8fa8b1cfcc	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-24T06:07:59Z"}	2022-01-24 06:07:59.40673+00
00000000-0000-0000-0000-000000000000	7609d254-a536-45c9-87d1-85ebd30e26ce	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-24T17:27:32Z"}	2022-01-24 17:27:32.276746+00
00000000-0000-0000-0000-000000000000	ea502b6c-feb4-49cb-86be-12961d1b01a2	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-24T17:27:32Z"}	2022-01-24 17:27:32.329108+00
00000000-0000-0000-0000-000000000000	762bc00a-ff29-4495-82f9-9f51c2cc5f13	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-24T17:52:41Z"}	2022-01-24 17:52:41.738189+00
00000000-0000-0000-0000-000000000000	1e762fd3-6b83-4329-9796-dbe4ea1f512f	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-24T17:52:45Z"}	2022-01-24 17:52:45.86505+00
00000000-0000-0000-0000-000000000000	94aaa55d-2473-4a62-8c3b-d4ae4bb1da4a	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-24T18:51:49Z"}	2022-01-24 18:51:49.559672+00
00000000-0000-0000-0000-000000000000	27b2c60a-42f7-4447-9ff2-d9425e99267d	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-24T18:51:49Z"}	2022-01-24 18:51:49.564563+00
00000000-0000-0000-0000-000000000000	d0e282e1-ec41-4fcf-95e8-494885271601	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-24T21:23:50Z"}	2022-01-24 21:23:50.227271+00
00000000-0000-0000-0000-000000000000	e2c77c20-ebfc-40b7-947c-8cff60d8135d	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-24T21:23:50Z"}	2022-01-24 21:23:50.235696+00
00000000-0000-0000-0000-000000000000	2c1a0896-28e3-46ac-90f8-06d2ba749cfd	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-24T21:40:54Z"}	2022-01-24 21:40:54.744043+00
00000000-0000-0000-0000-000000000000	4fa9e078-19d4-47cc-bb77-2a348d64c2a0	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-24T21:43:17Z"}	2022-01-24 21:43:17.465949+00
00000000-0000-0000-0000-000000000000	7df2e953-09e3-4e76-8e6d-261b61419e61	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-24T21:43:41Z"}	2022-01-24 21:43:41.880558+00
00000000-0000-0000-0000-000000000000	76222868-e842-4e65-8852-069eedefc33f	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-25T15:03:54Z"}	2022-01-25 15:03:54.75726+00
00000000-0000-0000-0000-000000000000	636af36b-e171-44ad-99d0-841aa46fb6a7	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-25T16:22:33Z"}	2022-01-25 16:22:33.802402+00
00000000-0000-0000-0000-000000000000	e7a81150-b12f-4b0a-a996-3e4e0337d650	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-25T16:22:33Z"}	2022-01-25 16:22:33.805507+00
00000000-0000-0000-0000-000000000000	a85e21d3-6214-4f86-8ec6-73e7bd9701c9	{"action":"user_repeated_signup","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"user","timestamp":"2022-01-26T23:33:07Z"}	2022-01-26 23:33:07.813507+00
00000000-0000-0000-0000-000000000000	435eff4e-d689-4bcf-a3a6-1041fa0da17b	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-26T23:33:11Z"}	2022-01-26 23:33:11.862877+00
00000000-0000-0000-0000-000000000000	fdb5fa49-342b-4146-ac8e-737f26ba3ab8	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-27T20:29:46Z"}	2022-01-27 20:29:46.918431+00
00000000-0000-0000-0000-000000000000	8d72da95-d8e5-45e0-86a9-0f59c403eeab	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-27T20:29:50Z"}	2022-01-27 20:29:50.363768+00
00000000-0000-0000-0000-000000000000	b9c3a6a2-c367-4c76-b7c8-4cb3ea003afa	{"action":"user_repeated_signup","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"user","timestamp":"2022-01-27T20:29:57Z"}	2022-01-27 20:29:57.511576+00
00000000-0000-0000-0000-000000000000	546c280b-8691-400f-91b2-1e7d41b00508	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-27T20:30:02Z"}	2022-01-27 20:30:02.265569+00
00000000-0000-0000-0000-000000000000	f361b47c-1cee-4eab-a14d-554cb1077a04	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-27T20:36:04Z"}	2022-01-27 20:36:04.662332+00
00000000-0000-0000-0000-000000000000	31f72d10-0480-4634-80f3-3640e69d36f1	{"action":"user_signedup","actor_id":"94a0b29a-f915-4e26-b6c4-deaf3a48ffab","actor_username":"malerba118+2@gmail.com","log_type":"team","timestamp":"2022-01-27T21:04:06Z"}	2022-01-27 21:04:06.480942+00
00000000-0000-0000-0000-000000000000	0852dd1f-06ab-4b07-b63f-74953a7b246c	{"action":"login","actor_id":"94a0b29a-f915-4e26-b6c4-deaf3a48ffab","actor_username":"malerba118+2@gmail.com","log_type":"account","timestamp":"2022-01-27T21:04:06Z"}	2022-01-27 21:04:06.487211+00
00000000-0000-0000-0000-000000000000	82a8ca0a-70be-4b7d-bdd4-0549ecb1daec	{"action":"logout","actor_id":"94a0b29a-f915-4e26-b6c4-deaf3a48ffab","actor_username":"malerba118+2@gmail.com","log_type":"account","timestamp":"2022-01-27T21:28:40Z"}	2022-01-27 21:28:40.709906+00
00000000-0000-0000-0000-000000000000	d27e651c-5796-4527-a699-205bf94aeb80	{"action":"login","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-27T21:41:35Z"}	2022-01-27 21:41:35.979042+00
00000000-0000-0000-0000-000000000000	bfaf7965-fcda-4221-b17d-fc6d264db616	{"action":"token_refreshed","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-28T00:15:08Z"}	2022-01-28 00:15:08.966873+00
00000000-0000-0000-0000-000000000000	f573deb3-537d-4b52-aa08-ed632b83c337	{"action":"token_revoked","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"token","timestamp":"2022-01-28T00:15:08Z"}	2022-01-28 00:15:08.999774+00
00000000-0000-0000-0000-000000000000	128a18ff-8869-4490-8572-2c199d36ef0e	{"action":"logout","actor_id":"48c92525-ec52-4601-a373-677f38d67011","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T00:23:03Z"}	2022-01-28 00:23:03.821111+00
00000000-0000-0000-0000-000000000000	0026e585-d43e-44df-86a8-91eda9d5a2e7	{"action":"login","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:23:23Z"}	2022-01-28 00:23:23.361036+00
00000000-0000-0000-0000-000000000000	f6f1ab0d-a305-4ad6-b683-0ab6a3c20115	{"action":"logout","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:23:39Z"}	2022-01-28 00:23:39.86475+00
00000000-0000-0000-0000-000000000000	7b796dde-668e-4fd7-8547-a216e2283edf	{"action":"login","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:24:04Z"}	2022-01-28 00:24:04.93274+00
00000000-0000-0000-0000-000000000000	78a87000-8c41-4d6a-aa26-175007846e0b	{"action":"logout","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:24:45Z"}	2022-01-28 00:24:45.820129+00
00000000-0000-0000-0000-000000000000	7ae38372-8471-461a-9e1e-28bc32e35fce	{"action":"login","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:25:08Z"}	2022-01-28 00:25:08.333585+00
00000000-0000-0000-0000-000000000000	377184ea-8fed-499b-9ef0-90bdd0bc6ad3	{"action":"logout","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:27:46Z"}	2022-01-28 00:27:46.396601+00
00000000-0000-0000-0000-000000000000	a3364203-7b54-4203-b942-e62d08f07fb9	{"action":"login","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:28:02Z"}	2022-01-28 00:28:02.808703+00
00000000-0000-0000-0000-000000000000	b922de55-e09d-4dc8-9810-fdee92ebaffc	{"action":"logout","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:32:33Z"}	2022-01-28 00:32:33.87756+00
00000000-0000-0000-0000-000000000000	a01e39fa-1272-47fe-976a-d8ddfa8c6df3	{"action":"login","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:32:49Z"}	2022-01-28 00:32:49.092056+00
00000000-0000-0000-0000-000000000000	841992ba-b415-46ac-b9c7-d56fb5e444a2	{"action":"logout","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:34:55Z"}	2022-01-28 00:34:55.768987+00
00000000-0000-0000-0000-000000000000	189672d3-1575-4b17-8a1e-b1e080d57bce	{"action":"login","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:35:35Z"}	2022-01-28 00:35:35.752396+00
00000000-0000-0000-0000-000000000000	6dea61bf-4b50-4b90-ace3-0b3ca425667c	{"action":"logout","actor_id":"4975184a-4093-4e63-882a-2c2f3b2405e0","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:36:45Z"}	2022-01-28 00:36:45.457171+00
00000000-0000-0000-0000-000000000000	b1c19b2b-662a-4e74-bce6-fcd0d98f6b48	{"action":"user_signedup","actor_id":"f44c5d43-b81f-450f-9d63-a30b1394ea9f","actor_username":"austin.malerba@gmail.com","log_type":"team","timestamp":"2022-01-28T00:39:29Z"}	2022-01-28 00:39:29.091764+00
00000000-0000-0000-0000-000000000000	57bd0713-326f-4596-b187-e9d551823174	{"action":"login","actor_id":"f44c5d43-b81f-450f-9d63-a30b1394ea9f","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:39:29Z"}	2022-01-28 00:39:29.097482+00
00000000-0000-0000-0000-000000000000	8d9905c9-3a2d-41e0-b884-82d250c97dab	{"action":"logout","actor_id":"f44c5d43-b81f-450f-9d63-a30b1394ea9f","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T00:41:45Z"}	2022-01-28 00:41:45.928637+00
00000000-0000-0000-0000-000000000000	a41cecc4-b106-4cab-bb9d-5d5ed2f3ed7e	{"action":"user_signedup","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"team","timestamp":"2022-01-28T00:42:06Z"}	2022-01-28 00:42:06.376701+00
00000000-0000-0000-0000-000000000000	0700a9a4-fd05-40a2-9e9b-0566ceee99b4	{"action":"login","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T00:42:06Z"}	2022-01-28 00:42:06.381819+00
00000000-0000-0000-0000-000000000000	666ccea7-8125-40b3-a4d0-af222b5f255f	{"action":"logout","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T01:01:27Z"}	2022-01-28 01:01:27.857646+00
00000000-0000-0000-0000-000000000000	e488a6e9-0504-41e2-a2df-f397585a7cba	{"action":"login","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T02:56:54Z"}	2022-01-28 02:56:54.743229+00
00000000-0000-0000-0000-000000000000	80462c8c-a42f-41dd-9d80-792ae21667cb	{"action":"logout","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T02:57:07Z"}	2022-01-28 02:57:07.778571+00
00000000-0000-0000-0000-000000000000	19960595-40b9-44b5-b643-f5b4e88eec97	{"action":"login","actor_id":"f44c5d43-b81f-450f-9d63-a30b1394ea9f","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T02:57:19Z"}	2022-01-28 02:57:19.512069+00
00000000-0000-0000-0000-000000000000	ce7119d7-d278-4adc-97d2-6b89dc1a8758	{"action":"logout","actor_id":"f44c5d43-b81f-450f-9d63-a30b1394ea9f","actor_username":"austin.malerba@gmail.com","log_type":"account","timestamp":"2022-01-28T03:03:51Z"}	2022-01-28 03:03:51.508054+00
00000000-0000-0000-0000-000000000000	09a8c5c3-60c3-43b1-a43f-1d1f6214361b	{"action":"login","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T03:04:25Z"}	2022-01-28 03:04:25.19656+00
00000000-0000-0000-0000-000000000000	27984625-dd3f-421a-a076-704dd2de7e19	{"action":"logout","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T03:04:47Z"}	2022-01-28 03:04:47.155282+00
00000000-0000-0000-0000-000000000000	13f601fa-4d95-47be-a585-da15cac8453c	{"action":"login","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T03:07:44Z"}	2022-01-28 03:07:44.401965+00
00000000-0000-0000-0000-000000000000	0c4c92cd-2536-41bb-96e3-c10acb9293e1	{"action":"logout","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T03:08:22Z"}	2022-01-28 03:08:22.864999+00
00000000-0000-0000-0000-000000000000	55348287-b192-4933-afd6-990be54a63c6	{"action":"login","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T12:45:49Z"}	2022-01-28 12:45:49.646597+00
00000000-0000-0000-0000-000000000000	44ea5825-0874-4fbe-b6c2-762aeca62f45	{"action":"logout","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T12:53:27Z"}	2022-01-28 12:53:27.591233+00
00000000-0000-0000-0000-000000000000	58aa52a2-228e-4562-8427-0c800c229272	{"action":"login","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T12:54:36Z"}	2022-01-28 12:54:36.05991+00
00000000-0000-0000-0000-000000000000	e2ef5afa-4c73-4b28-819c-b82139833a71	{"action":"logout","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T13:33:46Z"}	2022-01-28 13:33:46.747857+00
00000000-0000-0000-0000-000000000000	59bca150-f06d-49fa-8f21-b77d8aaaff5e	{"action":"login","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T13:34:19Z"}	2022-01-28 13:34:19.052112+00
00000000-0000-0000-0000-000000000000	93ec55ff-f6d7-439e-ac1c-ee2cec85778e	{"action":"logout","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T13:36:23Z"}	2022-01-28 13:36:23.530104+00
00000000-0000-0000-0000-000000000000	c49c7b51-2662-4bc6-b629-0a1b17d12cd5	{"action":"login","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T13:36:34Z"}	2022-01-28 13:36:34.821839+00
00000000-0000-0000-0000-000000000000	74c08293-8086-4381-9633-d71be33afa20	{"action":"logout","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T13:36:45Z"}	2022-01-28 13:36:45.456652+00
00000000-0000-0000-0000-000000000000	cafdf443-7bb1-460d-97a8-8f11249f95cc	{"action":"login","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T13:37:33Z"}	2022-01-28 13:37:33.794164+00
00000000-0000-0000-0000-000000000000	98ff461c-9adf-4596-a74f-6c8ab26ddb46	{"action":"logout","actor_id":"f2023f79-33a1-4279-acbe-d7e193c5f7e3","actor_username":"malerba118@gmail.com","log_type":"account","timestamp":"2022-01-28T13:37:37Z"}	2022-01-28 13:37:37.748135+00
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--

COPY auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at) FROM stdin;
f44c5d43-b81f-450f-9d63-a30b1394ea9f	f44c5d43-b81f-450f-9d63-a30b1394ea9f	{"sub": "f44c5d43-b81f-450f-9d63-a30b1394ea9f"}	email	2022-01-28 00:39:29.085996+00	2022-01-28 00:39:29.087869+00	2022-01-28 00:39:29.087869+00
f2023f79-33a1-4279-acbe-d7e193c5f7e3	f2023f79-33a1-4279-acbe-d7e193c5f7e3	{"sub": "f2023f79-33a1-4279-acbe-d7e193c5f7e3"}	email	2022-01-28 00:42:06.374352+00	2022-01-28 00:42:06.374528+00	2022-01-28 00:42:06.374528+00
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
00000000-0000-0000-0000-000000000000	f44c5d43-b81f-450f-9d63-a30b1394ea9f		authenticated	austin.malerba@gmail.com	$2a$10$uBA1TsA1zuRbwE.d//Sz6eHzkjLKvvjfuE.vKFTxwtq3jHQ02Q9hu	2022-01-28 00:39:29.093425+00	\N		\N		\N			\N	2022-01-28 02:57:19.514707+00	{"provider": "email", "providers": ["email"]}	{"name": "Austin Malerba", "avatar": "https://secure.gravatar.com/avatar/d51d4f060c004e4a36eff384b6b18dff"}	f	2022-01-28 00:39:29.070092+00	2022-01-28 00:39:29.070092+00	\N	\N			\N		0
00000000-0000-0000-0000-000000000000	f2023f79-33a1-4279-acbe-d7e193c5f7e3		authenticated	malerba118@gmail.com	$2a$10$oyxFKm6lOJXx1SqA9xDUG.N5vV6vedygulvT3BMzIpd9B9.LUVOKm	2022-01-28 00:42:06.378147+00	\N		\N		\N			\N	2022-01-28 13:37:33.797555+00	{"provider": "email", "providers": ["email"]}	{"name": "malerba118"}	f	2022-01-28 00:42:06.368155+00	2022-01-28 00:42:06.368155+00	\N	\N			\N		0
\.


--
-- Data for Name: comment_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comment_reactions (id, created_at, comment_id, user_id, reaction_type) FROM stdin;
a550dd70-f0aa-4088-99b4-e4128c5c5ff1	2022-01-28 00:39:48.408214+00	4e91c6db-767d-4d00-b96c-a792b29fa185	f44c5d43-b81f-450f-9d63-a30b1394ea9f	party-blob
91261358-5ac5-4120-a3a6-95d8e984d432	2022-01-28 00:42:35.39892+00	39f8e07d-02b8-439d-9bb3-4e189505a109	f2023f79-33a1-4279-acbe-d7e193c5f7e3	heart
51b12cdd-5086-4571-9554-912ad35443ec	2022-01-28 00:42:37.299912+00	39f8e07d-02b8-439d-9bb3-4e189505a109	f2023f79-33a1-4279-acbe-d7e193c5f7e3	like
1623f32b-25f9-460b-b619-a5f6d15da146	2022-01-28 00:59:57.388833+00	3be46f35-2c7d-456d-b768-edc5e5244c92	f2023f79-33a1-4279-acbe-d7e193c5f7e3	party-blob
9877902a-db88-44f1-a109-21ae17011f4c	2022-01-28 01:00:38.209989+00	3be46f35-2c7d-456d-b768-edc5e5244c92	f2023f79-33a1-4279-acbe-d7e193c5f7e3	heart
e3c4895e-f08a-494c-8056-0b06fcc4ee9e	2022-01-28 01:00:42.257525+00	3be46f35-2c7d-456d-b768-edc5e5244c92	f2023f79-33a1-4279-acbe-d7e193c5f7e3	like
42f3b3f9-897f-470d-90a7-1af4dd52266f	2022-01-28 03:07:55.454976+00	e09e2dff-19b8-4359-abdf-4b6d336924ae	f2023f79-33a1-4279-acbe-d7e193c5f7e3	heart
0e0cf3d3-b0b6-444a-95dd-1c242a2f3853	2022-01-28 03:08:19.505116+00	4e91c6db-767d-4d00-b96c-a792b29fa185	f2023f79-33a1-4279-acbe-d7e193c5f7e3	heart
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments (id, created_at, topic, comment, user_id, parent_id, mentioned_user_ids) FROM stdin;
4e91c6db-767d-4d00-b96c-a792b29fa185	2022-01-28 00:39:32.610331+00	tutorial-one	<p>test message</p>	f44c5d43-b81f-450f-9d63-a30b1394ea9f	\N	{}
e09e2dff-19b8-4359-abdf-4b6d336924ae	2022-01-28 00:40:01.715519+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="f44c5d43-b81f-450f-9d63-a30b1394ea9f" data-label="Austin Malerba">@Austin Malerba</span>. test</p>	f44c5d43-b81f-450f-9d63-a30b1394ea9f	4e91c6db-767d-4d00-b96c-a792b29fa185	{f44c5d43-b81f-450f-9d63-a30b1394ea9f}
39f8e07d-02b8-439d-9bb3-4e189505a109	2022-01-28 00:42:15.514874+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="f44c5d43-b81f-450f-9d63-a30b1394ea9f" data-label="Austin Malerba">@Austin Malerba</span> yoo</p>	f2023f79-33a1-4279-acbe-d7e193c5f7e3	4e91c6db-767d-4d00-b96c-a792b29fa185	{f44c5d43-b81f-450f-9d63-a30b1394ea9f}
3be46f35-2c7d-456d-b768-edc5e5244c92	2022-01-28 00:42:21.427987+00	tutorial-one	<p>yo</p>	f2023f79-33a1-4279-acbe-d7e193c5f7e3	\N	{}
4427d2ff-d032-400b-bcdf-c0f559ac8e4c	2022-01-28 03:08:05.097598+00	tutorial-one	<p><span data-type="mention" class="mention" data-id="f2023f79-33a1-4279-acbe-d7e193c5f7e3" data-label="malerba118">@malerba118</span> sdfsdf</p>	f2023f79-33a1-4279-acbe-d7e193c5f7e3	4e91c6db-767d-4d00-b96c-a792b29fa185	{f2023f79-33a1-4279-acbe-d7e193c5f7e3}
7385c569-ef44-45ea-a012-40b3648c52ae	2022-01-28 12:46:12.083231+00	tutorial-one	<pre><code>const foo = 1\n\nfunction foo() {\n console.log(2)\n}</code></pre>	f2023f79-33a1-4279-acbe-d7e193c5f7e3	\N	{}
\.


--
-- Data for Name: reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reactions (type, created_at, metadata) FROM stdin;
like	2022-01-27 21:39:21+00	{"url": "https://emojis.slackmojis.com/emojis/images/1588108689/8789/fb-like.png?1588108689", "label": "Like"}
heart	2022-01-14 15:05:34+00	{"url": "https://emojis.slackmojis.com/emojis/images/1596061862/9845/meow_heart.png?1596061862", "label": "Heart"}
party-blob	2022-01-27 21:52:38+00	{"url": "https://emojis.slackmojis.com/emojis/images/1547582922/5197/party_blob.gif?1547582922", "label": "Party Blob"}
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

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 85, true);


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
    ADD CONSTRAINT comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.comments(id) ON DELETE CASCADE;


--
-- Name: comments comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


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

