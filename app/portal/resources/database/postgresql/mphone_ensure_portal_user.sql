-- Narrow provisioning bridge for the signed Odoo integration.
-- The integration database role remains read-only outside this function.
create or replace function public.mphone_ensure_portal_user(
	p_domain_uuid uuid,
	p_email text
) returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $function$
declare
	v_email text := lower(btrim(p_email));
	v_user_uuid uuid;
	v_group_uuid uuid;
	v_count integer;
begin
	if v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' or length(v_email) > 254 then
		raise exception 'invalid_email';
	end if;
	if not exists (
		select 1 from public.v_domains
		where domain_uuid = p_domain_uuid and domain_enabled = true
	) then
		raise exception 'invalid_domain';
	end if;

	perform pg_advisory_xact_lock(hashtext(p_domain_uuid::text || '|' || v_email));
	select count(*), min(user_uuid::text)::uuid into v_count, v_user_uuid
	from public.v_users
	where domain_uuid = p_domain_uuid and lower(btrim(user_email)) = v_email
		and user_enabled = true;
	if v_count > 1 then
		raise exception 'fusion_user_ambiguous';
	end if;
	if v_user_uuid is null then
		v_user_uuid := gen_random_uuid();
		insert into public.v_users
			(user_uuid, domain_uuid, username, user_email, user_type, user_enabled, insert_date)
		values
			(v_user_uuid, p_domain_uuid, v_email, v_email, 'user', true, now());
	end if;

	select min(group_uuid::text)::uuid, count(*) into v_group_uuid, v_count
	from public.v_groups where group_name = 'user' and domain_uuid is null;
	if v_count <> 1 then
		raise exception 'fusion_user_group_ambiguous';
	end if;
	if not exists (
		select 1 from public.v_user_groups
		where user_uuid = v_user_uuid and group_uuid = v_group_uuid
	) then
		insert into public.v_user_groups
			(user_group_uuid, domain_uuid, group_name, group_uuid, user_uuid, insert_date)
		values
			(gen_random_uuid(), p_domain_uuid, 'user', v_group_uuid, v_user_uuid, now());
	end if;
	return v_user_uuid;
end;
$function$;

revoke all on function public.mphone_ensure_portal_user(uuid, text) from public;
grant execute on function public.mphone_ensure_portal_user(uuid, text) to fusionpbx_readonly;
