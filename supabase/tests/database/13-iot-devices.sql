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
               $$ insert into public.iot_devices (tenant_id, name, device_type, serial_number) values ('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', 'test iot device', 'smart watch', 'xxx-yyy-zzz') returning 1$$,
               ROW (1),
               'Should be able to insert a new iot device'
           );


