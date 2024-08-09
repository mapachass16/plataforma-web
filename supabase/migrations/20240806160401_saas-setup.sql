/**
  * -------------------------------------------------------
  * Section - SaaS schema setup and utility functions
  * -------------------------------------------------------
 */

-- revoke execution by default from public
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA PUBLIC REVOKE EXECUTE ON FUNCTIONS FROM anon, authenticated;

-- Create saas schema
CREATE SCHEMA IF NOT EXISTS saas;
GRANT USAGE ON SCHEMA saas to authenticated;
GRANT USAGE ON SCHEMA saas to service_role;

/**
  * -------------------------------------------------------
  * Section - Enums
  * -------------------------------------------------------
 */

/**
 * Invitation types are either email or link. Email invitations are sent to
 * a single user and can only be claimed once.  Link invitations can be used multiple times
 * Both expire after 24 hours
 */
DO
$$
    BEGIN
        -- check it account_role already exists on saas schema
        IF NOT EXISTS(SELECT 1
                      FROM pg_type t
                               JOIN pg_namespace n ON n.oid = t.typnamespace
                      WHERE t.typname = 'invitation_type'
                        AND n.nspname = 'saas') THEN
            CREATE TYPE saas.invitation_type AS ENUM ('one_time', '24_hour');
        end if;
    end;
$$;

/**
  * -------------------------------------------------------
  * Section - saas settings
  * -------------------------------------------------------
 */

CREATE TABLE IF NOT EXISTS saas.config
(
    config_key            text unique,
    config_value          text default '',
    metadata            jsonb default '{}'::jsonb
);

-- create config row
INSERT INTO saas.config (config_key, config_value) VALUES ('billing_provider', 'stripe');

-- enable select on the config table
GRANT SELECT, INSERT, UPDATE ON saas.config TO authenticated, service_role;

-- enable RLS on config
ALTER TABLE saas.config
    ENABLE ROW LEVEL SECURITY;

create policy "saas settings can be read by authenticated users" on saas.config
    for select
    to authenticated
    using (
    true
    );

create policy "saas settings can be inserted by authenticated users" on saas.config
    for insert 
    to authenticated
    with check (true);

create policy "saas settings can be updated by authenticated users" on saas.config
    for update 
    to authenticated
    with check (true);
/**
  * -------------------------------------------------------
  * Section - saas utility functions
  * -------------------------------------------------------
 */

/**
  saas.get_config("key")
  Get a value to check saas settings
  This is not accessible from the outside, so can only be used inside postgres functions
 */
CREATE OR REPLACE FUNCTION saas.get_config(p_config_key text)
RETURNS text AS $$
DECLARE
    v_config_value text;
BEGIN
    SELECT config_value INTO v_config_value
    FROM saas.config
    WHERE config_key = p_config_key;
    
    RETURN v_config_value;
END;
$$ LANGUAGE plpgsql;

grant execute on function saas.get_config(text) to authenticated, service_role;

/**
  saas.set_config("key", "value")
  Update or create a value in the saas settings
  This is not accessible from the outside, so can only be used inside postgres functions
 */
CREATE OR REPLACE FUNCTION saas.set_config(
    p_config_key text,
    p_config_value text
)
RETURNS boolean AS $$
BEGIN
    INSERT INTO saas.config (config_key, config_value)
    VALUES (p_config_key, p_config_value)
    ON CONFLICT (config_key)
    DO UPDATE SET 
        config_value = EXCLUDED.config_value;
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

grant execute on function saas.set_config(text, text) to authenticated, service_role;

/**
  * Automatic handling for maintaining created_at and updated_at timestamps
  * on tables
 */
CREATE OR REPLACE FUNCTION saas.trigger_set_timestamps()
    RETURNS TRIGGER AS
$$
BEGIN
    if TG_OP = 'INSERT' then
        NEW.created_at = now();
        NEW.updated_at = now();
    else
        NEW.updated_at = now();
        NEW.created_at = OLD.created_at;
    end if;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;


/**
  * Automatic handling for maintaining created_by and updated_by timestamps
  * on tables
 */
CREATE OR REPLACE FUNCTION saas.trigger_set_user_tracking()
    RETURNS TRIGGER AS
$$
BEGIN
    if TG_OP = 'INSERT' then
        NEW.created_by = auth.uid();
        NEW.updated_by = auth.uid();
    else
        NEW.updated_by = auth.uid();
        NEW.created_by = OLD.created_by;
    end if;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

/**
  saas.generate_chars_token(length)
  Generates a secure token - used internally for invitation tokens
  but could be used elsewhere.  Check out the invitations table for more info on
  how it's used
 */
CREATE OR REPLACE FUNCTION saas.generate_chars_token(length int)
    RETURNS text AS
$$
select regexp_replace(replace(
                              replace(replace(replace(encode(gen_random_bytes(length)::bytea, 'base64'), '/', ''), '+',
                                              ''), '\', ''),
                              '=',
                              ''), E'[\\n\\r]+', '', 'g');
$$ LANGUAGE sql;

grant execute on function saas.generate_chars_token(int) to authenticated;


/**
  saas.generate_token(length)
  Generates a numeric token - used internally for invitation tokens
  but could be used elsewhere.  Check out the invitations table for more info on
  how it's used
 */
CREATE OR REPLACE FUNCTION saas.generate_token(length int)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    characters text := '0123456789';
    token text := '';
    i integer := 0;
BEGIN
    IF length <= 0 THEN
        RETURN '';
    END IF;

    WHILE i < length LOOP
        token := token || substr(characters, floor(random() * length(characters))::int + 1, 1);
        i := i + 1;
    END LOOP;

    RETURN token;
END;
$$;

GRANT EXECUTE ON FUNCTION saas.generate_token(int) TO authenticated;