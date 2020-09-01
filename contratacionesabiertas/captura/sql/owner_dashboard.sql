DO $$
DECLARE 
  r record;
  i int;
  v_schema text[] := '{dashboard}';
  v_new_owner varchar := 'prueba_dashboard';
BEGIN
    FOR r IN 
        select 'ALTER TABLE "' || table_schema || '"."' || table_name || '" OWNER TO "' || v_new_owner || '";' as a from information_schema.tables where table_schema = ANY (v_schema)
        union all
        select 'ALTER TABLE "' || sequence_schema || '"."' || sequence_name || '" OWNER TO "' || v_new_owner || '";' as a from information_schema.sequences where sequence_schema = ANY (v_schema)
        union all
        select 'ALTER TABLE "' || table_schema || '"."' || table_name || '" OWNER TO "' || v_new_owner || '";' as a from information_schema.views where table_schema = ANY (v_schema)
        union all
        select 'ALTER FUNCTION "'||nsp.nspname||'"."'||p.proname||'"('||pg_get_function_identity_arguments(p.oid)||') OWNER TO "' || v_new_owner || '";' as a from pg_proc p join pg_namespace nsp ON p.pronamespace = nsp.oid where nsp.nspname = ANY (v_schema)
        union all
        select 'ALTER DATABASE "' || current_database() || '" OWNER TO "' || v_new_owner || '" '
    LOOP
        EXECUTE r.a;
    END LOOP;
    FOR i IN array_lower(v_schema,1) .. array_upper(v_schema,1)
    LOOP
        EXECUTE 'ALTER SCHEMA "' || v_schema[i] || '" OWNER TO "' || v_new_owner || '" ' ;
    END LOOP;
END
$$;