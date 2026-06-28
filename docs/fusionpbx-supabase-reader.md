# FusionPBX Supabase Reader

This document describes `sql/001_create_supabase_reader_view.sql`, which creates a PostgreSQL read-only account for Supabase to read enabled SIP extensions from FusionPBX.

## What It Creates

- Role: `supabase_reader`
- Password placeholder: `CHANGE_ME_STRONG_PASSWORD`
- View: `public.api_sip_extensions`
- Permission: `SELECT` on `public.api_sip_extensions`

The script does not grant write permissions and does not grant direct access to the source tables unless the database already has separate permissions outside this script.

## Connection Settings

Use these settings from Supabase:

- Host: `192.168.1.201`
- Port: `5432`
- Database: `fusionpbx`
- User: `supabase_reader`
- SSL mode: use the local PostgreSQL policy for this VM

The PostgreSQL server should listen on `localhost,192.168.1.201`. The `pg_hba.conf` access rule should allow the Supabase host `192.168.1.134/32` to connect as `supabase_reader`.

## View Columns

`public.api_sip_extensions` returns enabled extensions only:

- `extension_uuid`
- `extension`
- `sip_password`
- `display_name`
- `sip_domain`
- `enabled`

The view reads from `public.v_extensions` joined to `public.v_domains` by `domain_uuid`.

## Before Running

Edit the SQL file and replace:

```sql
CHANGE_ME_STRONG_PASSWORD
```

with a strong unique password for the Supabase connection.

## Apply

Run the script as a PostgreSQL user that can create roles, create views in `public`, and read `public.v_extensions` and `public.v_domains`.

Example:

```sh
psql -d fusionpbx -f sql/001_create_supabase_reader_view.sql
```

Remote connection test from the Supabase host:

```sh
psql -h 192.168.1.201 -p 5432 -U supabase_reader -d fusionpbx
```

## Verify Permissions

The SQL file includes checks for:

- granted privileges on `public.api_sip_extensions`
- `SELECT` access on the view
- absence of `INSERT`, `UPDATE`, and `DELETE` on the view
- whether the role has direct `SELECT` on `public.v_extensions` or `public.v_domains`
- a sample `SELECT` executed as `supabase_reader`

Expected result: `supabase_reader` can select from `public.api_sip_extensions` and cannot write to it.

## Rollback

Rollback commands are included at the bottom of the SQL file as comments:

```sql
REVOKE SELECT ON public.api_sip_extensions FROM supabase_reader;
REVOKE USAGE ON SCHEMA public FROM supabase_reader;
DROP VIEW IF EXISTS public.api_sip_extensions;
DROP ROLE IF EXISTS supabase_reader;
```

Only run the rollback after confirming `supabase_reader` is not used by another integration.
