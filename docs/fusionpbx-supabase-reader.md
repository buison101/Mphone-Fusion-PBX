# FusionPBX Supabase Reader

## Current Deployment (Source of Truth)

FusionPBX and Supabase are now installed on the **same server**.

- Server/LAN address: `192.168.1.201`
- FusionPBX application: `/var/www/fusionpbx`
- FusionPBX PostgreSQL database: host PostgreSQL on `192.168.1.201:5432`
- Supabase project root: `/opt/supabase/supabase-project`
- Supabase environment file: `/opt/supabase/supabase-project/.env`
- Supabase Compose file: `/opt/supabase/supabase-project/docker-compose.yml`
- FusionPBX login Edge Function: `/opt/supabase/supabase-project/volumes/functions/fusionpbx-login/index.ts`
- Supabase API/Kong endpoint: `http://192.168.1.201:8000`
- Supabase Docker network: `172.18.0.0/16`

Although both applications share one physical server, Supabase services run in
Docker. Connections from the Edge Function therefore originate from the Docker
network (for example `172.18.0.12`), not from `192.168.1.201`. PostgreSQL,
`pg_hba.conf`, and UFW must allow `supabase_reader` from `172.18.0.0/16`.

The active app login flow is:

```text
Linphone fork app
  -> Supabase Edge Function: fusionpbx-login
  -> FusionPBX PostgreSQL using supabase_reader
  -> verify the FusionPBX user password
  -> return the user's enabled SIP extensions
```

This document also describes `sql/001_create_supabase_reader_view.sql`, which
was originally intended to create a read-only view for enabled SIP extensions.

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

The PostgreSQL server should listen on `localhost,192.168.1.201`. The active
`pg_hba.conf` access rules should allow `supabase_reader` from the local server
and the Supabase Docker network:

```text
host    fusionpbx    supabase_reader    192.168.1.201/32    scram-sha-256
host    fusionpbx    supabase_reader    172.18.0.0/16       scram-sha-256
```

Do not restore the obsolete Supabase host rule for `192.168.1.134`; that was the
address used before Supabase was moved onto this server.

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

Connection test from the server host:

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
