CREATE FUNCTION increment_counter_text(table_name text, table_column_name text, column_name text, id text, step integer)
  RETURNS VOID AS $$
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

  $$ LANGUAGE plpgsql;

-- counter_cache_text('users', 'facebook_id', 'user_identifier', 'timelines_count');
CREATE FUNCTION counter_cache_text()
  RETURNS trigger AS $$
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
        PERFORM increment_counter_text(table_name, table_fk_name, fk_value, counter_name, -1);
      END IF;

      IF TG_OP = 'INSERT' OR fk_changed THEN
        record := NEW;
        EXECUTE 'SELECT ($1).' || fk_name INTO fk_value USING record;
        PERFORM increment_counter_text(table_name, table_fk_name, fk_value, counter_name, 1);
      END IF;

      RETURN record;
    END;
  $$ LANGUAGE plpgsql;


CREATE TRIGGER update_users_timelines_count
  AFTER DELETE OR INSERT OR UPDATE ON timeline_publishers
  FOR EACH ROW EXECUTE PROCEDURE counter_cache_text('users', 'facebook_id', 'user_identifier', 'timelines_count');
