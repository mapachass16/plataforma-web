BEGIN;
create extension "basejump-supabase_test_helpers" version '0.0.6';

select plan(6);

-- make sure we're setup for enabling personal tenants
-- update saas.config
-- set enable_team_tenants = true;

-- create the users we need for testing
select tests.create_supabase_user('primary_owner');
select tests.create_supabase_user('invited_owner');
select tests.create_supabase_user('member');
select tests.create_supabase_user('testing_member');

--- Setup the tests
select tests.authenticate_as('primary_owner');
select create_tenant('test', 'Test Tenant');

set role postgres;

insert into saas.tenant_user (tenant_id, tenant_role, user_id)
values (get_tenant_id('test'), 'member', tests.get_supabase_uid('member'));
insert into saas.tenant_user (tenant_id, tenant_role, user_id)
values (get_tenant_id('test'), 'owner', tests.get_supabase_uid('invited_owner'));
insert into saas.tenant_user (tenant_id, tenant_role, user_id)
values (get_tenant_id('test'), 'member', tests.get_supabase_uid('testing_member'));

---  can NOT remove a member unless your an owner
select tests.authenticate_as('member');

SELECT throws_ok(
               $$ select remove_tenant_member(get_tenant_id('test'), tests.get_supabase_uid('testing_member')) $$,
               'Only tenant owners can access this function'
           );

--- CAN remove a member if you're an owner
select tests.authenticate_as('invited_owner');

select lives_ok(
               $$select remove_tenant_member(get_tenant_id('test'), tests.get_supabase_uid('testing_member'))$$,
               'Owners should be able to remove members'
           );

select tests.authenticate_as('testing_member');

SELECT is(
               (select saas.has_role_on_tenant(get_tenant_id('test'))),
               false,
               'Should no longer have access to the tenant'
           );

--- can NOT remove the primary owner
select tests.authenticate_as('invited_owner');

--- attempt to delete primary owner
select remove_tenant_member(get_tenant_id('test'), tests.get_supabase_uid('primary_owner'));

--- CAN remove ANOTHER owner as an owner as long as that owner is NOT the primary owner

select tests.authenticate_as('primary_owner');

SELECT is(
               (select saas.has_role_on_tenant(get_tenant_id('test'), 'owner')),
               true,
               'Primary owner should still be on the tenant'
           );

select lives_ok(
               $$select remove_tenant_member(get_tenant_id('test'), tests.get_supabase_uid('invited_owner'))$$,
               'Owners should be able to remove owners that arent the primary'
           );

select tests.authenticate_as('invited_owner');

SELECT is(
               (select saas.has_role_on_tenant(get_tenant_id('test'))),
               false,
               'Should no longer have access to the tenant'
           );

SELECT *
FROM finish();

ROLLBACK;