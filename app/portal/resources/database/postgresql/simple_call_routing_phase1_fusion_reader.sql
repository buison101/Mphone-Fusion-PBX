-- Read-only execution-state access for the server-side Customer Platform adapter.
-- This role cannot mutate FusionPBX resources; publication writes remain in a
-- separately authorized FusionPBX-side service introduced by later phases.

grant usage on schema public to supabase_reader;
grant select on public.v_destinations to supabase_reader;
grant select on public.v_dialplans to supabase_reader;
grant select on public.v_dialplan_details to supabase_reader;
grant select on public.v_ring_groups to supabase_reader;
grant select on public.v_ring_group_destinations to supabase_reader;
grant select on public.v_ivr_menus to supabase_reader;
grant select on public.v_ivr_menu_options to supabase_reader;
grant select on public.v_recordings to supabase_reader;

-- Rollback:
-- revoke select on public.v_destinations, public.v_dialplans,
--   public.v_dialplan_details, public.v_ring_groups,
--   public.v_ring_group_destinations, public.v_ivr_menus,
--   public.v_ivr_menu_options, public.v_recordings from supabase_reader;
