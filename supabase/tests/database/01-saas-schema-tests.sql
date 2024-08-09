BEGIN;
create extension "basejump-supabase_test_helpers" version '0.0.6';

select plan(20);

select has_schema('saas', 'Saas schema should exist');

select has_table('saas', 'config', 'Saas config table should exist');
select has_table('saas', 'tenants', 'Saas tenants table should exist');
select has_table('saas', 'tenant_user', 'Saas tenant_users table should exist');
--select has_table('saas', 'invitations', 'Saas invitations table should exist');
--select has_table('saas', 'billing_customers', 'Saas billing_customers table should exist');
--select has_table('saas', 'billing_subscriptions', 'Saas billing_subscriptions table should exist');

select tests.rls_enabled('saas');

select columns_are('saas', 'config',
                   Array ['config_key', 'config_value', 'metadata'],
                   'Saas config table should have the correct columns');


select function_returns('saas', 'generate_token', Array ['integer'], 'text',
                        'Saas generate_token function should exist');
select function_returns('saas', 'trigger_set_timestamps', 'trigger',
                        'Saas trigger_set_timestamps function should exist');

SELECT schema_privs_are('saas', 'anon', Array [NULL], 'Anon should not have access to saas schema');

-- set the role to anonymous for verifying access tests
set role anon;
select throws_ok('select saas.get_config()');
select throws_ok('select saas.get_config(''billing_provider'')');
select throws_ok('select saas.generate_token(1)');

-- set the role to the service_role for testing access
set role service_role;
select ok(saas.get_config('billing_provider') is not null),
       'Saas get_config should be accessible to the service role';

-- set the role to authenticated for tests
set role authenticated;
select ok(saas.get_config('billing_provider') is not null), 'Saas get_config should be accessible to authenticated users';
select ok(saas.set_config('test', 'test')),
       'Saas set_config should be accessible to authenticated users';
select isnt_empty('select * from saas.config', 'authenticated users should have access to Saas config');
select ok(saas.generate_chars_token(1) is not null),
       'Saas generate_token should be accessible to authenticated users';
-- Check if the function exists
SELECT has_function('saas', 'generate_token', ARRAY['integer'],
       'Function generate_token should exist'
);

-- Check if the generated token has the correct length
SELECT is(length(saas.generate_token(6)), 6,
       'Generated token should have a length of 6'
);

-- Check if the generated token contains only numbers
SELECT matches(saas.generate_token(6), '^[0-9]+$',
       'Generated token should contain only numbers'
);

SELECT *
FROM finish();

ROLLBACK;