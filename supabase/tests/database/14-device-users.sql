BEGIN;
create extension "basejump-supabase_test_helpers" version '0.0.6';

select plan(1);


-- Create the users we plan on using for testing
select tests.create_supabase_user('test1');
select tests.create_supabase_user('test_member');
select tests.create_supabase_user('test_owner');

--- start acting as an authenticated user
select tests.authenticate_as('test1');

-- setup inaccessible tests for a known tenant ID
insert into saas.tenants (id, name, slug, personal_tenant)
values ('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', 'nobody in test can access me', 'no-access', false);

SELECT row_eq(
               $$ insert into public.device_users (tenant_id, first_name, last_name, date_of_birth, gender) values ('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', 'test iot device','last-name', '2024-08-28', 'M') returning 1$$,
               ROW (1),
               'Should be able to insert a new iot device'
           );
