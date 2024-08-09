BEGIN;
create extension "basejump-supabase_test_helpers" version '0.0.6';

select plan(34);

-- make sure we're setup for enabling personal tenants
--update saas.config
--set enable_team_tenants = true;

-- Create the users we plan on using for testing
select tests.create_supabase_user('test1');
select tests.create_supabase_user('test2');
select tests.create_supabase_user('test_member');
select tests.create_supabase_user('test_owner');
select tests.create_supabase_user('test_random_owner');

--- start acting as an authenticated user
select tests.authenticate_as('test_random_owner');

-- setup inaccessible tests for a known tenant ID
insert into saas.tenants (id, name, slug, personal_tenant)
values ('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f', 'nobody in test can access me', 'no-access', false);

------------
--- Primary Owner
------------
select tests.authenticate_as('test1');

-- should be able to create a team tenant when they're enabled
SELECT row_eq(
               $$ insert into saas.tenants (id, name, slug, personal_tenant) values ('8fcec130-27cd-4374-9e47-3303f9529479', 'test team', 'test-team', false) returning 1$$,
               ROW (1),
               'Should be able to create a new team tenant'
           );

-- newly created team should be owned by current user
SELECT row_eq(
               $$ select primary_owner_user_id from saas.tenants where id = '8fcec130-27cd-4374-9e47-3303f9529479' $$,
               ROW (tests.get_supabase_uid('test1')),
               'Creating a new team tenant should make the current user the primary owner'
           );

-- should add that user to the tenant as an owner
SELECT row_eq(
               $$ select user_id, tenant_role from saas.tenant_user where tenant_id = '8fcec130-27cd-4374-9e47-3303f9529479'::uuid $$,
               ROW (tests.get_supabase_uid('test1'), 'owner'::saas.tenant_role),
               'Inserting an tenant should also add an tenant_user for the current user'
           );

-- should be able to get your own role for the tenant
SELECT row_eq(
               $$ select public.current_user_tenant_role('8fcec130-27cd-4374-9e47-3303f9529479') $$,
               ROW (jsonb_build_object(
                       'tenant_role', 'owner',
                       'is_primary_owner', TRUE,
                       'is_personal_tenant', FALSE
                   )),
               'Primary owner should be able to get their own role'
           );

-- cannot change the tenants.primary_owner_user_id directly
SELECT throws_ok(
               $$ update saas.tenants set primary_owner_user_id = tests.get_supabase_uid('test2') where personal_tenant = false $$,
               'You do not have permission to update this field'
           );

-- cannot delete the primary_owner_user_id from the tenant_user table
select row_eq(
               $$
    	delete from saas.tenant_user where user_id = tests.get_supabase_uid('test1');
    	select user_id from saas.tenant_user where user_id = tests.get_supabase_uid('test1');
    $$,
               ROW (tests.get_supabase_uid('test1')::uuid),
               'Should not be able to delete the primary_owner_user_id from the tenant_user table'
           );

-- owners should be able to add invitations
SELECT row_eq(
               $$ insert into saas.invitations (tenant_id, tenant_role, token, invitation_type) values ('8fcec130-27cd-4374-9e47-3303f9529479', 'member', 'test_member_single_use_token', 'one_time') returning 1 $$,
               ROW (1),
               'Owners should be able to add invitations for new members'
           );

SELECT row_eq(
               $$ insert into saas.invitations (tenant_id, tenant_role, token, invitation_type) values ('8fcec130-27cd-4374-9e47-3303f9529479', 'owner', 'test_owner_single_use_token', 'one_time') returning 1 $$,
               ROW (1),
               'Owners should be able to add invitations for new owners'
           );

-- should not be able to add new users directly into team tenants
SELECT throws_ok(
               $$ insert into saas.tenant_user (tenant_id, tenant_role, user_id) values ('8fcec130-27cd-4374-9e47-3303f9529479', 'owner', tests.get_supabase_uid('test2')) $$,
               'new row violates row-level security policy for table "tenant_user"'
           );

-- cannot change personal_tenant setting no matter who you are
SELECT throws_ok(
               $$ update saas.tenants set personal_tenant = true where id = '8fcec130-27cd-4374-9e47-3303f9529479' $$,
               'You do not have permission to update this field'
           );

-- owner can update their team name
SELECT results_eq(
               $$ update saas.tenants set name = 'test' where id = '8fcec130-27cd-4374-9e47-3303f9529479' returning name $$,
               $$ values('test') $$,
               'Owner can update their team name'
           );

-- all tenants (personal and team) should be returned by get_tenants_with_role test
SELECT ok(
               (select '8fcec130-27cd-4374-9e47-3303f9529479' IN
                       (select saas.get_tenants_with_role())),
               'Team tenant should be returned by the saas.get_tenants_with_role function'
           );

-- shouoldn't return any tenants if you're not a member of
SELECT ok(
               (select 'd126ecef-35f6-4b5d-9f28-d9f00a9fb46f' NOT IN
                       (select saas.get_tenants_with_role())),
               'Team tenants not a member of should NOT be returned by the saas.get_tenants_with_role function'
           );

-- should return true for saas.has_role_on_tenant
SELECT ok(
               (select saas.has_role_on_tenant('8fcec130-27cd-4374-9e47-3303f9529479', 'owner')),
               'Should return true for saas.has_role_on_tenant'
           );

SELECT ok(
               (select saas.has_role_on_tenant('8fcec130-27cd-4374-9e47-3303f9529479')),
               'Should return true for saas.has_role_on_tenant'
           );

-- should return FALSE when not on the tenant
SELECT ok(
               (select NOT saas.has_role_on_tenant('d126ecef-35f6-4b5d-9f28-d9f00a9fb46f')),
               'Should return false for saas.has_role_on_tenant'
           );

-----------
--- Tenant User Setup
-----------
select tests.clear_authentication();
set role postgres;

-- insert tenant_user for the member test
insert into saas.tenant_user (tenant_id, tenant_role, user_id)
values ('8fcec130-27cd-4374-9e47-3303f9529479', 'member', tests.get_supabase_uid('test_member'));
-- insert tenant_user for the owner test
insert into saas.tenant_user (tenant_id, tenant_role, user_id)
values ('8fcec130-27cd-4374-9e47-3303f9529479', 'owner', tests.get_supabase_uid('test_owner'));

-----------
--- Member
-----------
select tests.authenticate_as('test_member');

-- should now have access to the tenant
SELECT is(
               (select count(*)::int from saas.tenants where id = '8fcec130-27cd-4374-9e47-3303f9529479'),
               1,
               'Should now have access to the tenant'
           );

-- members cannot update tenant info
SELECT results_ne(
               $$ update saas.tenants set name = 'test' where id = '8fcec130-27cd-4374-9e47-3303f9529479' returning 1 $$,
               $$ values(1) $$,
               'Member cannot can update their team name'
           );

-- tenant_user should have a role of member
SELECT row_eq(
               $$ select tenant_role from saas.tenant_user where tenant_id = '8fcec130-27cd-4374-9e47-3303f9529479' and user_id = tests.get_supabase_uid('test_member')$$,
               ROW ('member'::saas.tenant_role),
               'Should have the correct tenant role after accepting an invitation'
           );

-- should be able to get your own role for the tenant
SELECT row_eq(
               $$ select public.current_user_tenant_role('8fcec130-27cd-4374-9e47-3303f9529479') $$,
               ROW (jsonb_build_object(
                       'tenant_role', 'member',
                       'is_primary_owner', FALSE,
                       'is_personal_tenant', FALSE
                   )),
               'Member should be able to get their own role'
           );

-- Should NOT show up as an owner in the permissions check
SELECT ok(
               (select '8fcec130-27cd-4374-9e47-3303f9529479' NOT IN
                       (select saas.get_tenants_with_role('owner'))),
               'Newly added tenant ID should not be in the list of tenants returned by saas.get_tenants_with_role("owner")'
           );

-- Should be able ot get a full list of tenants when no permission passed in
SELECT ok(
               (select '8fcec130-27cd-4374-9e47-3303f9529479' IN
                       (select saas.get_tenants_with_role())),
               'Newly added tenant ID should be in the list of tenants returned by saas.get_tenants_with_role()'
           );

-- should return true for saas.has_role_on_tenant
SELECT ok(
               (select saas.has_role_on_tenant('8fcec130-27cd-4374-9e47-3303f9529479')),
               'Should return true for saas.has_role_on_tenant'
           );

-- should return false for the owner lookup
SELECT ok(
               (select NOT saas.has_role_on_tenant('8fcec130-27cd-4374-9e47-3303f9529479', 'owner')),
               'Should return false for saas.has_role_on_tenant'
           );

-----------
--- Non-Primary Owner
-----------
select tests.authenticate_as('test_owner');

-- should now have access to the tenant
SELECT is(
               (select count(*)::int from saas.tenants where id = '8fcec130-27cd-4374-9e47-3303f9529479'),
               1,
               'Should now have access to the tenant'
           );

-- tenant_user should have a role of member
SELECT row_eq(
               $$ select tenant_role from saas.tenant_user where tenant_id = '8fcec130-27cd-4374-9e47-3303f9529479' and user_id = tests.get_supabase_uid('test_owner')$$,
               ROW ('owner'::saas.tenant_role),
               'Should have the expected tenant role'
           );

-- should be able to get your own role for the tenant
SELECT row_eq(
               $$ select public.current_user_tenant_role('8fcec130-27cd-4374-9e47-3303f9529479') $$,
               ROW (jsonb_build_object(
                       'tenant_role', 'owner',
                       'is_primary_owner', FALSE,
                       'is_personal_tenant', FALSE
                   )),
               'Owner should be able to get their own role'
           );

-- Should NOT show up as an owner in the permissions check
SELECT ok(
               (select '8fcec130-27cd-4374-9e47-3303f9529479' IN
                       (select saas.get_tenants_with_role('owner'))),
               'Newly added tenant ID should not be in the list of tenants returned by saas.get_tenants_with_role("owner")'
           );

-- Should be able ot get a full list of tenants when no permission passed in
SELECT ok(
               (select '8fcec130-27cd-4374-9e47-3303f9529479' IN
                       (select saas.get_tenants_with_role())),
               'Newly added tenant ID should be in the list of tenants returned by saas.get_tenants_with_role()'
           );

SELECT results_eq(
               $$ update saas.tenants set name = 'test2' where id = '8fcec130-27cd-4374-9e47-3303f9529479' returning name $$,
               $$ values('test2') $$,
               'New owners can update their team name'
           );

-----------
-- Strangers
----------

select tests.authenticate_as('test2');

-- non members / owner cannot update team name
SELECT results_ne(
               $$ update saas.tenants set name = 'test3' where id = '8fcec130-27cd-4374-9e47-3303f9529479' returning 1$$,
               $$ select 1 $$
           );
-- non member / owner should receive no results from tenants
SELECT is(
               (select count(*)::int from saas.tenants where personal_tenant = false),
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