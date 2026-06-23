-- Create a read-only PostgreSQL role and API view for Supabase access.
-- Replace CHANGE_ME_STRONG_PASSWORD before running this script.

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM pg_roles
		WHERE rolname = 'supabase_reader'
	) THEN
		CREATE ROLE supabase_reader LOGIN PASSWORD 'CHANGE_ME_STRONG_PASSWORD';
	ELSE
		ALTER ROLE supabase_reader WITH LOGIN PASSWORD 'CHANGE_ME_STRONG_PASSWORD';
	END IF;
END
$$;

CREATE OR REPLACE VIEW public.api_sip_extensions AS
SELECT
	e.extension_uuid,
	e.extension,
	e.password AS sip_password,
	e.effective_caller_id_name AS display_name,
	d.domain_name AS sip_domain,
	e.enabled
FROM public.v_extensions AS e
JOIN public.v_domains AS d
	ON d.domain_uuid = e.domain_uuid
WHERE e.enabled = 'true';

GRANT USAGE ON SCHEMA public TO supabase_reader;
GRANT SELECT ON public.api_sip_extensions TO supabase_reader;

-- Permission checks.
SELECT
	grantee,
	privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
	AND table_name = 'api_sip_extensions'
	AND grantee = 'supabase_reader'
ORDER BY privilege_type;

SELECT
	has_table_privilege('supabase_reader', 'public.api_sip_extensions', 'SELECT') AS can_select_view,
	has_table_privilege('supabase_reader', 'public.api_sip_extensions', 'INSERT') AS can_insert_view,
	has_table_privilege('supabase_reader', 'public.api_sip_extensions', 'UPDATE') AS can_update_view,
	has_table_privilege('supabase_reader', 'public.api_sip_extensions', 'DELETE') AS can_delete_view,
	has_table_privilege('supabase_reader', 'public.v_extensions', 'SELECT') AS can_select_v_extensions,
	has_table_privilege('supabase_reader', 'public.v_domains', 'SELECT') AS can_select_v_domains;

SET ROLE supabase_reader;
SELECT *
FROM public.api_sip_extensions
LIMIT 1;
RESET ROLE;

-- Rollback.
-- REVOKE SELECT ON public.api_sip_extensions FROM supabase_reader;
-- REVOKE USAGE ON SCHEMA public FROM supabase_reader;
-- DROP VIEW IF EXISTS public.api_sip_extensions;
-- DROP ROLE IF EXISTS supabase_reader;
