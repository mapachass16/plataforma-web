BEGIN;
create extension "basejump-supabase_test_helpers" version '0.0.6';

select plan(17);
-- make sure we're setup for enabling personal tenants
-- update saas.config
-- set enable_team_tenants = true;

-- setup users needed for testing
select tests.create_supabase_user('primary');
select tests.create_supabase_user('owner');
select tests.create_supabase_user('member');

--- start acting as an authenticated user
select tests.authenticate_as('primary');

insert into saas.tenants (id, name, slug, personal_tenant)
values ('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', 'test', 'test', false);

-- setup users for tests
set local role postgres;
insert into saas.tenant_user (tenant_id, user_id, tenant_role)
values ('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', tests.get_supabase_uid('owner'), 'owner');
insert into saas.tenant_user (tenant_id, user_id, tenant_role)
values ('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', tests.get_supabase_uid('member'), 'member');

--------
-- Acting as member
--------
select tests.authenticate_as('member');

-- can't update role directly in the tenant_user table
SELECT results_ne(
               $$ update saas.tenant_user set tenant_role = 'owner' where tenant_id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' and user_id = tests.get_supabase_uid('member') returning 1 $$,
               $$ values(1) $$,
               'Members should not be able to update their own role'
           );

-- members should not be able to update any user roles
SELECT throws_ok(
               $$ select update_tenant_user_role('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', tests.get_supabase_uid('member'),  'owner', false) $$,
               'You must be an owner of the tenant to update a users role'
           );

-- member should still be only a member
SELECT row_eq(
               $$ select tenant_role from saas.tenant_user where tenant_id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' and user_id = tests.get_supabase_uid('member') $$,
               ROW ('member'::saas.tenant_role),
               'Member should still be a member'
           );

-------
-- Acting as Non Primary Owner
-------
select tests.authenticate_as('owner');

-- can't update role directly in the tenant_user table
SELECT results_ne(
               $$ update saas.tenant_user set tenant_role = 'owner' where tenant_id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' and user_id = tests.get_supabase_uid('member') returning 1 $$,
               $$ values(1) $$,
               'Members should not be able to update their own role'
           );

-- non primary owner cannot change primary owner
SELECT throws_ok(
               $$ select update_tenant_user_role('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', tests.get_supabase_uid('member'),  'owner', true) $$,
               'You must be the primary owner of the tenant to change the primary owner'
           );

SELECT row_eq(
               $$ select tenant_role from saas.tenant_user where tenant_id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' and user_id = tests.get_supabase_uid('member') $$,
               ROW ('member'::saas.tenant_role),
               'Member should still be a member since primary owner change failed'
           );


-- trying to update accoutn user role of primary owner should fail
SELECT throws_ok(
               $$ select update_tenant_user_role('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', tests.get_supabase_uid('primary'),  'owner', false) $$,
               'You must be the primary owner of the tenant to change the primary owner'
           );

--- primary owner should still be the same
SELECT row_eq(
               $$ select tenant_role from saas.tenant_user where tenant_id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' and user_id = tests.get_supabase_uid('primary') $$,
               ROW ('owner'::saas.tenant_role),
               'Primary owner should still be the same'
           );

-- tenant should have the same primary_owner_user_id
SELECT row_eq(
               $$ select primary_owner_user_id from saas.tenants where id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' $$,
               ROW (tests.get_supabase_uid('primary')),
               'Primary owner should still be the same'
           );

-- non primary owner should be able to update other users roles
SELECT lives_ok(
               $$ select update_tenant_user_role('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', tests.get_supabase_uid('member'),  'owner', false) $$,
               'Non primary owner should be able to update other users roles'
           );

-- member should now be an owner
SELECT row_eq(
               $$ select tenant_role from saas.tenant_user where tenant_id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' and user_id = tests.get_supabase_uid('member') $$,
               ROW ('owner'::saas.tenant_role),
               'Member should now be an owner'
           );

-------
-- Acting as primary owner
-------
select tests.authenticate_as('primary');

-- can't update role directly in the tenant_user table
SELECT results_ne(
               $$ update saas.tenant_user set tenant_role = 'member' where tenant_id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' and user_id = tests.get_supabase_uid('member') returning 1 $$,
               $$ values(1) $$,
               'Members should not be able to update their own role'
           );

-- primary owner should be able to change user back to a member
SELECT lives_ok(
               $$ select update_tenant_user_role('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', tests.get_supabase_uid('member'),  'member', false) $$,
               'Primary owner should be able to change user back to a member'
           );

-- member should now be a member
SELECT row_eq(
               $$ select tenant_role from saas.tenant_user where tenant_id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' and user_id = tests.get_supabase_uid('member') $$,
               ROW ('member'::saas.tenant_role),
               'Member should now be a member'
           );

-- primary owner can change a user into a primary owner
SELECT lives_ok(
               $$ select update_tenant_user_role('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', tests.get_supabase_uid('member'),  'owner', true) $$,
               'Primary owner should be able to change user into a primary owner'
           );

-- member should now be a primary owner
SELECT row_eq(
               $$ select tenant_role from saas.tenant_user where tenant_id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' and user_id = tests.get_supabase_uid('member') $$,
               ROW ('owner'::saas.tenant_role),
               'Member should now be a primary owner'
           );

-- tenant primary_owner_user_id should be updated
SELECT row_eq(
               $$ select primary_owner_user_id from saas.tenants where id = 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' $$,
               ROW (tests.get_supabase_uid('member')),
               'Primary owner should be updated'
           );

SELECT *
FROM finish();

ROLLBACK;