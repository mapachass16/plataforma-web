BEGIN;
create extension "basejump-supabase_test_helpers" version '0.0.6';

select plan(15);

--- we insert a user into auth.users and return the id into user_id to use

select tests.create_supabase_user('test1', 'test1@test.com');

select tests.create_supabase_user('test2');

------------
--- Primary Owner
------------
select tests.authenticate_as('test1');

-- should create the personal tenant automatically with the same ID as the user
SELECT row_eq(
               $$ select id, primary_owner_user_id, personal_tenant, name from saas.tenants order by created_at desc limit 1 $$,
               ROW (tests.get_supabase_uid('test1'), tests.get_supabase_uid('test1'), true, 'test1'::text),
               'Inserting a user should create a personal tenant when personal tenants are enabled'
           );

-- should add that user to the tenant as an owner
SELECT row_eq(
               $$ select user_id, tenant_id, tenant_role from saas.tenant_user $$,
               ROW (tests.get_supabase_uid('test1'), (select id from saas.tenants where personal_tenant = true), 'owner'::saas.tenant_role),
               'Inserting a user should also add an tenant_user for the created tenant'
           );

-- should be able to get your own role for the tenant
SELECT row_eq(
               $$ with data as (select id from saas.tenants where personal_tenant = true) select public.current_user_tenant_role(data.id) from data $$,
               ROW (jsonb_build_object(
                       'tenant_role', 'owner',
                       'is_primary_owner', TRUE,
                       'is_personal_tenant', TRUE
                   )),
               'Primary owner should be able to get their own role'
           );

-- cannot change the tenants.primary_owner_user_id
SELECT throws_ok(
               $$ update saas.tenants set primary_owner_user_id = '5d94cce7-054f-4d01-a9ec-51e7b7ba8d59' where personal_tenant = true $$,
               'You do not have permission to update this field'
           );

-- cannot delete the primary_owner_user_id from the tenant_user table
select row_eq(
               $$
    	delete from saas.tenant_user where user_id = tests.get_supabase_uid('test1');
    	select user_id from saas.tenant_user where user_id = tests.get_supabase_uid('test1');
    $$,
               ROW (tests.get_supabase_uid('test1')),
               'Should not be able to delete the primary_owner_user_id from the tenant_user table'
           );

-- owners should be able to add invitations to personal tenants
SELECT throws_ok(
    $$
    INSERT INTO saas.invitations (tenant_id, tenant_role, token, invitation_type) 
    VALUES ((select id from saas.tenants where personal_tenant = true), 'owner', 'test', 'one_time')
    $$,
    'new row violates row-level security policy for table "invitations"'
);

-- should not be able to add new users with role 'owner' to personal tenants
SELECT throws_ok(
               $$ insert into saas.tenant_user (tenant_id, tenant_role, user_id) values ((select id from saas.tenants where personal_tenant = true), 'owner', '5d94cce7-054f-4d01-a9ec-51e7b7ba8d59') $$,
               'new row violates row-level security policy for table "tenant_user"'
           );

-- cannot change personal_tenant setting no matter who you are
SELECT throws_ok(
               $$ update saas.tenants set personal_tenant = false where personal_tenant = true $$,
               'You do not have permission to update this field'
           );

-- owner can update their team name
SELECT results_eq(
               $$ update saas.tenants set name = 'test' where id = (select id from saas.tenants where personal_tenant = true) returning name $$,
               $$ select 'test' $$,
               'Owner can update their team name'
           );

-- personal tenant should be returned by the saas.get_tenants_with_role function
SELECT results_eq(
               $$ select saas.get_tenants_with_role() $$,
               $$ select id from saas.tenants where personal_tenant = true $$,
               'Personal tenant should be returned by the saas.get_tenants_with_role function'
           );

-- should get true for personal tenant using has_role_on_tenant function
SELECT results_eq(
               $$ select saas.has_role_on_tenant((select id from saas.tenants where personal_tenant = true), 'owner') $$,
               $$ select true $$,
               'Should get true for personal tenant using has_role_on_tenant function'
           );

-----------
-- Strangers
----------
select tests.authenticate_as('test2');

-- non members / owner cannot update team name
SELECT results_ne(
               $$ update saas.tenants set name = 'test' where primary_owner_user_id = tests.get_supabase_uid('test1') returning 1$$,
               $$ select 1 $$
           );

-- non member / owner should receive no results from tenants
SELECT is(
               (select count(*)::int
                from saas.tenants
                where primary_owner_user_id <> tests.get_supabase_uid('test2')),
               0,
               'Non members / owner should receive no results from tenants'
           );


--------------
-- Anonymous
--------------
select tests.clear_authentication();

-- anonymous should receive no results from tenants
SELECT throws_ok(
               $$ select * from saas.tenants $$,
               'permission denied for schema saas'
           );

-- anonymous cannot update team name
SELECT throws_ok(
               $$ update saas.tenants set name = 'test' returning 1 $$,
               'permission denied for schema saas'
           );

SELECT *
FROM finish();

ROLLBACK;