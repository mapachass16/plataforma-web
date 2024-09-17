/**
 * Returns the current user's role within a given tenant_id
*/
create or replace function public.current_user_tenant_role_service(tenant_id uuid)
    returns jsonb
    language plpgsql
as
$$
DECLARE
    response jsonb;
BEGIN

    select jsonb_build_object(
                   'tenant_role', wu.tenant_role,
                   'is_primary_owner', a.primary_owner_user_id = auth.uid(),
                   'is_personal_tenant', a.personal_tenant
               )
    into response
    from saas.tenant_user wu
             join saas.tenants a on a.id = wu.tenant_id
    where wu.tenant_id = current_user_tenant_role_service.tenant_id;

    -- if the user is not a member of the tenant, throw an error
    if response ->> 'tenant_role' IS NULL then
        raise exception 'Not found';
    end if;

    return response;
END
$$;

grant execute on function public.current_user_tenant_role_service(uuid) to authenticated;


/**
  Returns a list of current tenant members. Only tenant owners can access this function.
  It's a security definer because it requries us to lookup personal_tenants for existing members so we can
  get their names.
 */
create or replace function public.get_tenant_members_service(tenant_id uuid, results_limit integer default 50,
                                                      results_offset integer default 0)
    returns json
    language plpgsql
    security definer
    set search_path = saas
as
$$
BEGIN

    -- only tenant owners can access this function
    if (select public.current_user_tenant_role_service(get_tenant_members_service.tenant_id) ->> 'tenant_role' <> 'owner') then
        raise exception 'Only tenant owners can access this function';
    end if;

    return (select json_agg(
                           json_build_object(
                                   'user_id', wu.user_id,
                                   'tenant_role', wu.tenant_role,
                                   'firstname', pro.first_name,
                                   'lastname', pro.last_name,
                                   'username', p.name,
                                   'email', u.email,
                                   'is_primary_owner', a.primary_owner_user_id = wu.user_id
                               )
                       )
            from saas.tenant_user wu
                     join saas.tenants a on a.id = wu.tenant_id
                     join saas.tenants p on p.primary_owner_user_id = wu.user_id and p.personal_tenant = true
                     join auth.users u on u.id = wu.user_id
                     join saas.profiles pro on pro.id = wu.user_id
            where wu.tenant_id = get_tenant_members_service.tenant_id
            limit coalesce(get_tenant_members_service.results_limit, 50) offset coalesce(get_tenant_members_service.results_offset, 0));
END;
$$;

grant execute on function public.get_tenant_members_service(uuid, integer, integer) to service_role;