-- Install only the permissions owned by Simple Call Routing Phase 1.
-- This intentionally does not run the global menu or permission reset.

with permission_names(name) as (values
	('did_inventory_view'),
	('did_inventory_manage'),
	('did_assign'),
	('did_suspend'),
	('did_release'),
	('did_transfer'),
	('call_routing_takeover'),
	('call_routing_publish_advanced'),
	('call_routing_cancel_transition'),
	('call_routing_release'),
	('call_routing_view_snapshot')
)
insert into public.v_permissions (
	permission_uuid,application_uuid,application_name,permission_name,permission_description,insert_date
)
select md5('mphone-simple-call-routing:' || name)::uuid,
	'3c50c052-baa4-4717-8ecc-2a4e6491b4af'::uuid,'Portal',name,
	'Mphone Simple Call Routing narrow staff permission',now()
from permission_names p
where not exists (select 1 from public.v_permissions existing where existing.permission_name=p.name);

with permission_names(name) as (values
	('did_inventory_view'),
	('did_inventory_manage'),
	('did_assign'),
	('did_suspend'),
	('did_release'),
	('did_transfer'),
	('call_routing_takeover'),
	('call_routing_publish_advanced'),
	('call_routing_cancel_transition'),
	('call_routing_release'),
	('call_routing_view_snapshot')
)
insert into public.v_group_permissions (
	group_permission_uuid,domain_uuid,permission_name,permission_protected,
	permission_assigned,group_name,group_uuid,insert_date
)
select md5('mphone-simple-call-routing:superadmin:' || p.name)::uuid,
	g.domain_uuid,p.name,'false','true',g.group_name,g.group_uuid,now()
from permission_names p
join public.v_groups g on g.group_name='superadmin'
where not exists (
	select 1 from public.v_group_permissions existing
	where existing.group_uuid=g.group_uuid and existing.permission_name=p.name
);

-- Rollback removes only these exact deterministic rows:
-- delete from public.v_group_permissions where group_permission_uuid in
--   (select md5('mphone-simple-call-routing:superadmin:' || name)::uuid from (values
--     ('did_inventory_view'),('did_inventory_manage'),('did_assign'),('did_suspend'),
--     ('did_release'),('did_transfer'),('call_routing_takeover'),
--     ('call_routing_publish_advanced'),('call_routing_cancel_transition'),
--     ('call_routing_release'),('call_routing_view_snapshot')) names(name));
-- delete from public.v_permissions where permission_uuid in
--   (select md5('mphone-simple-call-routing:' || name)::uuid from (values
--     ('did_inventory_view'),('did_inventory_manage'),('did_assign'),('did_suspend'),
--     ('did_release'),('did_transfer'),('call_routing_takeover'),
--     ('call_routing_publish_advanced'),('call_routing_cancel_transition'),
--     ('call_routing_release'),('call_routing_view_snapshot')) names(name));
