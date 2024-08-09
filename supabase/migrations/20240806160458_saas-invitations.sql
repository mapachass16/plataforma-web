/**
  * -------------------------------------------------------
  * Section - Invitations
  * -------------------------------------------------------
 */

/**
  * Invitations are sent to users to join a tenant
  * They pre-define the role the user should have once they join
 */
create table if not exists saas.invitations
(
    -- the id of the invitation
    id                 uuid unique                                              not null default extensions.uuid_generate_v4(),
    -- what role should invitation accepters be given in this tenant
    tenant_role       saas.tenant_role                                    not null,
    -- the tenant the invitation is for
    tenant_id         uuid references saas.tenants (id) on delete cascade not null,
    -- unique token used to accept the invitation
    token              text unique                                              not null default saas.generate_token(6),
    -- who created the invitation
    invited_by_user_id uuid references auth.users                               not null,
    -- tenant name. filled in by a trigger
    tenant_name       text,
    -- when the invitation was last updated
    updated_at         timestamp with time zone,
    -- when the invitation was created
    created_at         timestamp with time zone,
    -- what type of invitation is this
    invitation_type    saas.invitation_type                                 not null,
    primary key (id)
);

-- Open up access to invitations
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE saas.invitations TO authenticated, service_role;

-- manage timestamps
CREATE TRIGGER saas_set_invitations_timestamp
    BEFORE INSERT OR UPDATE
    ON saas.invitations
    FOR EACH ROW
EXECUTE FUNCTION saas.trigger_set_timestamps();

/**
  * This funciton fills in tenant info and inviting user email
  * so that the recipient can get more info about the invitation prior to
  * accepting.  It allows us to avoid complex permissions on tenants
 */
CREATE OR REPLACE FUNCTION saas.trigger_set_invitation_details()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.invited_by_user_id = auth.uid();
    NEW.tenant_name = (select name from saas.tenants where id = NEW.tenant_id);
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER saas_trigger_set_invitation_details
    BEFORE INSERT
    ON saas.invitations
    FOR EACH ROW
EXECUTE FUNCTION saas.trigger_set_invitation_details();

-- enable RLS on invitations
alter table saas.invitations
    enable row level security;

/**
  * -------------------------
  * Section - RLS Policies
  * -------------------------
  * This is where we define access to tables in the saas schema
 */

 create policy "Invitations viewable by tenant owners" on saas.invitations
    for select
    to authenticated
    using (
            created_at > (now() - interval '24 hours')
        and
            saas.has_role_on_tenant(tenant_id, 'owner') = true
    );


create policy "Invitations can be created by tenant owners" on saas.invitations
    for insert
    to authenticated
    with check (
        (SELECT personal_tenant
             FROM saas.tenants
             WHERE id = tenant_id) = false
        -- the inserting user should be an owner of the tenant
        and
            (saas.has_role_on_tenant(tenant_id, 'owner') = true)
    );

create policy "Invitations can be deleted by tenant owners" on saas.invitations
    for delete
    to authenticated
    using (
    saas.has_role_on_tenant(tenant_id, 'owner') = true
    );



/**
  * -------------------------------------------------------
  * Section - Public functions
  * -------------------------------------------------------
  * Each of these functions exists in the public name space because they are accessible
  * via the API.  it is the primary way developers can interact with saas tenants
 */


/**
  Returns a list of currently active invitations for a given tenant
 */

create or replace function public.get_tenant_invitations(tenant_id uuid, results_limit integer default 25,
                                                          results_offset integer default 0)
    returns json
    language plpgsql
as
$$
BEGIN
    -- only tenant owners can access this function
    if (select public.current_user_tenant_role(get_tenant_invitations.tenant_id) ->> 'tenant_role' <> 'owner') then
        raise exception 'Only tenant owners can access this function';
    end if;

    return (select json_agg(
                           json_build_object(
                                   'tenant_role', i.tenant_role,
                                   'created_at', i.created_at,
                                   'invitation_type', i.invitation_type,
                                   'invitation_id', i.id
                               )
                       )
            from saas.invitations i
            where i.tenant_id = get_tenant_invitations.tenant_id
              and i.created_at > now() - interval '24 hours'
            limit coalesce(get_tenant_invitations.results_limit, 25) offset coalesce(get_tenant_invitations.results_offset, 0));
END;
$$;

grant execute on function public.get_tenant_invitations(uuid, integer, integer) to authenticated;


/**
  * Allows a user to accept an existing invitation and join a tenant
  * This one exists in the public schema because we want it to be called
  * using the supabase rpc method
 */
create or replace function public.accept_invitation(lookup_invitation_token text)
    returns jsonb
    language plpgsql
    security definer set search_path = public, saas
as
$$
declare
    lookup_tenant_id       uuid;
    declare new_member_role saas.tenant_role;
    lookup_tenant_slug     text;
begin
    select i.tenant_id, i.tenant_role, a.slug
    into lookup_tenant_id, new_member_role, lookup_tenant_slug
    from saas.invitations i
             join saas.tenants a on a.id = i.tenant_id
    where i.token = lookup_invitation_token
      and i.created_at > now() - interval '24 hours';

    if lookup_tenant_id IS NULL then
        raise exception 'Invitation not found';
    end if;

    if lookup_tenant_id is not null then
        -- we've validated the token is real, so grant the user access
        insert into saas.tenant_user (tenant_id, user_id, tenant_role)
        values (lookup_tenant_id, auth.uid(), new_member_role);
        -- email types of invitations are only good for one usage
        delete from saas.invitations where token = lookup_invitation_token and invitation_type = 'one_time';
    end if;
    return json_build_object('tenant_id', lookup_tenant_id, 'tenant_role', new_member_role, 'slug',
                             lookup_tenant_slug);
EXCEPTION
    WHEN unique_violation THEN
        raise exception 'You are already a member of this tenant';
end;
$$;

grant execute on function public.accept_invitation(text) to authenticated;


/**
  * Allows a user to lookup an existing invitation and join a tenant
  * This one exists in the public schema because we want it to be called
  * using the supabase rpc method
 */
create or replace function public.lookup_invitation(lookup_invitation_token text)
    returns json
    language plpgsql
    security definer set search_path = public, saas
as
$$
declare
    name              text;
    invitation_active boolean;
begin
    select tenant_name,
           case when id IS NOT NULL then true else false end as active
    into name, invitation_active
    from saas.invitations
    where token = lookup_invitation_token
      and created_at > now() - interval '24 hours'
    limit 1;
    return json_build_object('active', coalesce(invitation_active, false), 'tenant_name', name);
end;
$$;

grant execute on function public.lookup_invitation(text) to authenticated;


/**
  Allows a user to create a new invitation if they are an owner of an tenant
 */
create or replace function public.create_invitation(tenant_id uuid, tenant_role saas.tenant_role,
                                                    invitation_type saas.invitation_type)
    returns json
    language plpgsql
as
$$
declare
    new_invitation saas.invitations;
begin
    insert into saas.invitations (tenant_id, tenant_role, invitation_type, invited_by_user_id)
    values (tenant_id, tenant_role, invitation_type, auth.uid())
    returning * into new_invitation;

    return json_build_object('token', new_invitation.token);
end
$$;

grant execute on function public.create_invitation(uuid, saas.tenant_role, saas.invitation_type) to authenticated;

/**
  Allows an owner to delete an existing invitation
 */

create or replace function public.delete_invitation(invitation_id uuid)
    returns void
    language plpgsql
as
$$
begin
    -- verify tenant owner for the invitation
    if saas.has_role_on_tenant(
               (select tenant_id from saas.invitations where id = delete_invitation.invitation_id), 'owner') <>
       true then
        raise exception 'Only tenant owners can delete invitations';
    end if;

    delete from saas.invitations where id = delete_invitation.invitation_id;
end
$$;

grant execute on function public.delete_invitation(uuid) to authenticated;