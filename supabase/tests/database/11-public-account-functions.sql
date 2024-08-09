BEGIN;
create extension "basejump-supabase_test_helpers" version '0.0.6';

select plan(29);

--- we insert a user into auth.users and return the id into user_id to use
select tests.create_supabase_user('test1');
select tests.create_supabase_user('test2');
select tests.create_supabase_user('test_member');

select tests.authenticate_as('test1');
select create_tenant('my-tenant', 'My tenant');
select create_tenant(name => 'My Tenant 2', slug => 'my-tenant-2');

select is(
               (select (get_tenant_by_slug('my-tenant') ->> 'tenant_id')::uuid),
               (select id from saas.tenants where slug = 'my-tenant'),
               'get_tenant_by_slug returns the correct tenant_id'
           );

select is(
               (select json_array_length(get_tenants())),
               3,
               'get_tenants returns 2 tenants'
           );


-- insert known tenant id into tenants table for testing later
insert into saas.tenants (id, slug, name)
values ('00000000-0000-0000-0000-000000000000', 'my-known-tenant', 'My Known Tenant');

-- get_tenant_id should return the correct tenant id
select is(
               (select public.get_tenant_id('my-known-tenant')),
               '00000000-0000-0000-0000-000000000000'::uuid,
               'get_tenant_id should return the correct id'
           );

select is(
               (select (public.get_tenant('00000000-0000-0000-0000-000000000000') ->> 'tenant_id')::uuid),
               '00000000-0000-0000-0000-000000000000'::uuid,
               'get_tenant should be able to return a known tenant'
           );

----- updating tenants should work
select update_tenant('00000000-0000-0000-0000-000000000000', slug => 'my-updated-slug');

select is(
               (select slug from saas.tenants where id = '00000000-0000-0000-0000-000000000000'),
               'my-updated-slug',
               'Updating slug should have been successful for the owner'
           );

select update_tenant('00000000-0000-0000-0000-000000000000', name => 'My Updated Tenant Name');

select is(
               (select name from saas.tenants where id = '00000000-0000-0000-0000-000000000000'),
               'My Updated Tenant Name',
               'Updating team name should have been successful for the owner'
           );

select update_tenant('00000000-0000-0000-0000-000000000000', metadata => jsonb_build_object('foo', 'bar'));

select is(
               (select metadata from saas.tenants where id = '00000000-0000-0000-0000-000000000000'),
               '{
                 "foo": "bar"
               }'::jsonb,
               'Updating meta should have been successful for the owner'
           );

select update_tenant('00000000-0000-0000-0000-000000000000', metadata => jsonb_build_object('foo', 'bar2'));

select is(
               (select metadata from saas.tenants where id = '00000000-0000-0000-0000-000000000000'),
               '{
                 "foo": "bar2"
               }'::jsonb,
               'Updating meta should have been successful for the owner'
           );

select update_tenant('00000000-0000-0000-0000-000000000000', metadata => jsonb_build_object('foo2', 'bar'));

select is(
               (select metadata from saas.tenants where id = '00000000-0000-0000-0000-000000000000'),
               '{
                 "foo": "bar2",
                 "foo2": "bar"
               }'::jsonb,
               'Updating meta should have merged by default'
           );

select update_tenant('00000000-0000-0000-0000-000000000000', metadata => jsonb_build_object('foo3', 'bar'),
                      replace_metadata => true);

select is(
               (select metadata from saas.tenants where id = '00000000-0000-0000-0000-000000000000'),
               '{
                 "foo3": "bar"
               }'::jsonb,
               'Updating meta should support replacing when you want'
           );

-- get_tenant should return public metadata
select is(
               (select (get_tenant('00000000-0000-0000-0000-000000000000') ->> 'metadata')::jsonb),
               '{
                 "foo3": "bar"
               }'::jsonb,
               'get_tenant should return public metadata'
           );

select update_tenant('00000000-0000-0000-0000-000000000000', name => 'My Updated Tenant Name 2');

select is(
               (select metadata from saas.tenants where id = '00000000-0000-0000-0000-000000000000'),
               '{
                 "foo3": "bar"
               }'::jsonb,
               'Updating other fields should not affect public metadata'
           );

--- test that we cannot update tenants we belong to but don't own

select tests.clear_authentication();
set role postgres;

insert into saas.tenant_user (tenant_id, tenant_role, user_id)
values ('00000000-0000-0000-0000-000000000000', 'member', tests.get_supabase_uid('test_member'));

select tests.authenticate_as('test_member');

select throws_ok(
               $$select update_tenant('00000000-0000-0000-0000-000000000000', slug => 'my-updated-slug-200')$$,
               'Only tenant owners can update an tenant'
           );
-------
--- Second user
-------

select tests.authenticate_as('test2');

select throws_ok(
               $$select get_tenant('00000000-0000-0000-0000-000000000000')$$,
               'Not found'
           );

select throws_ok(
               $$select get_tenant_by_slug('my-known-tenant')$$,
               'Not found'
           );

select throws_ok(
               $$select current_user_tenant_role('00000000-0000-0000-0000-000000000000')$$,
               'Not found'
           );

select is(
               (select json_array_length(get_tenants())),
               1,
               'get_tenants returns 1 tenants (personal)'
           );

select is(
               (select get_personal_tenant() ->> 'tenant_id'),
               auth.uid()::text,
               'get_personal_tenant should return the correct tenant_id'
           );


select throws_ok($$select create_tenant('my-tenant', 'My tenant')$$,
                 'An tenant with that unique ID already exists');

select create_tenant('My Tenant & 3');

select is(
               (select (get_tenant_by_slug('my-tenant-3') ->> 'tenant_id')::uuid),
               (select id from saas.tenants where slug = 'my-tenant-3'),
               'get_tenant_by_slug returns the correct tenant_id'
           );

select is(
               (select json_array_length(get_tenants())),
               2,
               'get_tenants returns 2 tenants (personal and team)'
           );


-- Should not be able to update an tenant you aren't a member of

select throws_ok(
               $$select update_tenant('00000000-0000-0000-0000-000000000000', slug => 'my-tenant-new-slug')$$,
               'Not found'
           );

-- Anon users should not have access to any of these functions

select tests.clear_authentication();

select throws_ok(
               $$select get_tenant('00000000-0000-0000-0000-000000000000')$$,
               'permission denied for function get_tenant'
           );

select throws_ok(
               $$select get_tenant_by_slug('my-tenant-3')$$,
               'permission denied for function get_tenant_by_slug'
           );

select throws_ok(
               $$select current_user_tenant_role('00000000-0000-0000-0000-000000000000')$$,
               'permission denied for function current_user_tenant_role'
           );

select throws_ok(
               $$select get_tenants()$$,
               'permission denied for function get_tenants'
           );


---- some functions should work for service_role users
select tests.authenticate_as_service_role();

select is(
               (select (get_tenant('00000000-0000-0000-0000-000000000000') ->> 'tenant_id')::uuid),
               '00000000-0000-0000-0000-000000000000'::uuid,
               'get_tenant should return the correct tenant_id'
           );

select is(
               (select (get_tenant_by_slug('my-updated-slug') ->> 'tenant_id')::uuid),
               (select id from saas.tenants where slug = 'my-updated-slug'),
               'get_tenant_by_slug returns the correct tenant_id'
           );

select update_tenant('00000000-0000-0000-0000-000000000000', slug => 'my-updated-slug-300');

select is(
               (select get_tenant('00000000-0000-0000-0000-000000000000') ->> 'slug'),
               'my-updated-slug-300',
               'Updating the tenant slug should work for service_role users'
           );

SELECT *
FROM finish();

ROLLBACK;