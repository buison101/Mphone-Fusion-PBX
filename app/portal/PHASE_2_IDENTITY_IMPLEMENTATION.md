# Customer Identity Phase 2 — Pilot Core Implementation

Status: implemented for the shared-LAN pilot on 2026-08-22.

This increment replaces the temporary Fusion user subject with a Customer
Identity subject when a migrated account signs in by canonical email. Legacy
username login and direct Extension login remain available for rollback.

## Architecture decisions used for the pilot

- The self-hosted Supabase PostgreSQL database owns Customer Platform data.
- Email canonicalization is trim plus lowercase. No provider-specific rewriting
  (such as removing dots or plus suffixes) is performed.
- Each eligible Fusion user is migrated as one individual Customer and its owner.
- Existing `v_extension_users` rows become explicit `can_use=true` and
  `can_manage=true` assignments.
- Existing Fusion user password hashes seed the application password provider;
  SIP passwords are never used as account passwords.
- Existing Fusion emails are considered verified only for this controlled LAN
  pilot. A production migration must use an approved verified source or an email
  verification campaign.
- One Identity may have multiple memberships. The API automatically selects the
  only membership inside the requested tenant; ambiguous contexts are rejected.
- One Extension may be assigned to multiple Identities. Every sensitive request
  still checks the requesting Identity/Customer assignment.

## Data model

Migration: `/opt/supabase/supabase-project/volumes/db/init/mphone_identity_phase2.sql`

The migration adds:

- `mphone_identities`
- `mphone_identity_providers`
- `mphone_customers`
- `mphone_memberships`
- `mphone_customer_tenants`
- `mphone_extension_assignments`
- `mphone_extension_notification_recipients`
- `mphone_identity_migration_exceptions`
- transient unlogged staging tables used by the repeatable reconciliation job

Phase 1 device sessions now accept `subject_kind=customer_identity` and retain
the Identity, Customer, Membership, and compatibility Fusion user references.
Customer UUID remains independent from Fusion `domain_uuid`, ready for later
Subscription and Billing foreign keys.

## Reconciliation

Run:

```sh
/opt/supabase/supabase-project/scripts/migrate_mphone_phase2.sh
```

The job exports only enabled Fusion users and enabled Extension links, stages
them in Supabase, upserts deterministic pilot Customers and assignments, records
exceptions, clears staging data, and prints reconciliation totals. It is
idempotent and does not delete FusionPBX or Mphone data.

Current pilot result:

```text
Identities:             4
Customers:              4
Active memberships:     4
Active assignments:     5
Unresolved exceptions:  1
```

The exception is the user in Fusion domain `call.mphone.vn`. That Domain is not
mapped because the approved LAN shared tenant still points to `192.168.1.201`.

## API behavior

The existing versioned endpoint remains stable:

```text
POST /functions/v1/mphone-auth-v2/login
POST /functions/v1/mphone-auth-v2/refresh
POST /functions/v1/mphone-auth-v2/logout
POST /functions/v1/mphone-auth-v2/logout-all
GET  /functions/v1/mphone-auth-v2/session
GET  /functions/v1/mphone-auth-v2/devices
POST /functions/v1/mphone-auth-v2/revoke-device
GET  /functions/v1/mphone-auth-v2/me
GET  /functions/v1/mphone-auth-v2/memberships
GET  /functions/v1/mphone-auth-v2/extensions
```

An eligible email login now returns `subject_kind=customer_identity`, plus
`identity_uuid`, `customer_uuid`, `membership_uuid`, and explicitly assigned
Extensions. The JWT keeps a separate compatibility `user_uuid` claim so narrow
FusionPBX operations can retain their existing permission checks.

Refresh revalidates Identity, email verification, Customer, Membership, tenant,
Fusion user, Domain, and session status. Call-forward and push registration
revalidate the requested Extension assignment server-side. Removing an
assignment therefore blocks sensitive access even while an access token remains
unexpired.

## Android integration

Mphone accepts the unchanged login response contract and now persists the
Identity, Customer, and Membership context inside its Keystore-backed encrypted
session record. Managed Account and Multi-SIP suspension/restoration behavior is
unchanged.

Debug builds continue to use the proven LAN endpoint
`http://192.168.1.201:8000`. Release builds resolve the configured pilot endpoint
to `https://login.mphone.vn`.

## Verification

- schema migration applied twice successfully;
- reconciliation job rerun without duplicate records;
- migrated account returned `customer_identity` with Identity, Customer,
  Membership, two assigned Extensions, access token, and rotating refresh token;
- `/me`, `/memberships`, `/extensions`, and `/devices` returned 200;
- assigned Extension call-forward returned 200;
- an Extension not assigned to the current Identity returned 403;
- direct Extension login still returned one Extension and valid v2 credentials;
- Extension actor access to `/me` returned 403;
- refresh rotation and logout returned 200;
- temporary integration password hashes were restored and integration sessions
  were logged out or explicitly revoked after testing.

## Deliberately not enabled yet

- Google OAuth: provider mapping is ready, but no Google credentials or public
  trusted HTTPS callback exists. Automatic email-based provider linking remains
  prohibited.
- Self-service registration, email verification, recovery, email change, and
  provider unlinking: these require outbound email and recent-auth contracts.
- Customer picker: the pilot rejects ambiguous tenant membership instead of
  guessing.
- Browser Portal bearer-session bridge: the current Portal still uses the
  FusionPBX PHP session. It must be migrated as a separate guarded increment
  because its websocket and every PHP service currently depend on that session.
- Billing and subscriptions: the schema is ready to reference `customer_uuid`,
  but no billing records or payment integration are introduced here.

## Rollback

No destructive rollback is required. Disable or remove a Customer's active
membership/tenant mapping to stop Phase 2 login, or use the existing legacy
username login during the pilot. Phase 2 tables are additive. Do not drop them
while `customer_identity` sessions remain active; revoke those sessions first.
