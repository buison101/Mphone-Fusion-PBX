create table if not exists v_portal_call_tags (
	tag_uuid uuid primary key,
	domain_uuid uuid not null,
	name varchar(80) not null,
	normalized_name varchar(80) not null,
	color_token varchar(20) not null default 'primary',
	enabled boolean not null default true,
	tag_order numeric not null default 0,
	insert_date timestamptz not null default now(),
	insert_user uuid,
	update_date timestamptz,
	update_user uuid
);
create unique index if not exists v_portal_call_tags_domain_name_uq on v_portal_call_tags(domain_uuid, normalized_name);
create index if not exists v_portal_call_tags_domain_enabled_idx on v_portal_call_tags(domain_uuid, enabled, tag_order);

create table if not exists v_portal_call_tag_assignments (
	assignment_uuid uuid primary key,
	domain_uuid uuid not null,
	xml_cdr_uuid uuid not null,
	tag_uuid uuid not null references v_portal_call_tags(tag_uuid) on delete cascade,
	insert_date timestamptz not null default now(),
	insert_user uuid
);
create unique index if not exists v_portal_call_tag_assignments_call_tag_uq on v_portal_call_tag_assignments(domain_uuid, xml_cdr_uuid, tag_uuid);
create index if not exists v_portal_call_tag_assignments_call_idx on v_portal_call_tag_assignments(domain_uuid, xml_cdr_uuid);
create index if not exists v_portal_call_tag_assignments_filter_idx on v_portal_call_tag_assignments(domain_uuid, tag_uuid, xml_cdr_uuid);

create table if not exists v_portal_call_notes (
	note_uuid uuid primary key,
	domain_uuid uuid not null,
	xml_cdr_uuid uuid not null,
	user_uuid uuid not null,
	note_text text not null,
	offset_seconds numeric,
	insert_date timestamptz not null default now(),
	insert_user uuid,
	update_date timestamptz,
	update_user uuid,
	constraint v_portal_call_notes_offset_ck check (offset_seconds is null or (offset_seconds >= 0 and offset_seconds <= 86400))
);
create index if not exists v_portal_call_notes_call_idx on v_portal_call_notes(domain_uuid, xml_cdr_uuid, insert_date);
create index if not exists v_portal_call_notes_user_idx on v_portal_call_notes(domain_uuid, user_uuid);
