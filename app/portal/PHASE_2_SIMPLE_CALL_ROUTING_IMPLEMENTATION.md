# Phase 2 — Mphone Staff DID Lifecycle Implementation

Status: implemented locally on 2026-08-31.

Phase 2 adds the staff-only DID inventory and lifecycle vertical slice on top of the Phase 1 foundation. Customer routing writes remain disabled.

## Implemented

- Portal Superadmin inventory at `/p/admin/dids`.
- Create and reserve inventory DIDs with canonical E.164 validation, provider state, capabilities, revision, reason, and audit.
- Assign an inbound-capable, provider-active reserved DID to an authorized Customer and Domain.
- Select initial Customer-owned Extensions; cross-Customer or Domain-mismatched UUIDs are rejected again in Customer Platform SQL.
- Prepare the initial FusionPBX Destination and dialplan disabled, register exact generated UUIDs/fingerprint, validate, enable, verify, publish, and only then activate the assignment.
- Create outbound caller-ID entitlement only when the DID capability permits it; activate it only after assignment publication.
- Suspend by publishing an explicit `CALL_REJECTED` service route and suspending outbound caller-ID entitlement.
- Resume by cloning and republishing the last verified Simple desired state.
- Release by publishing the service route, revoking entitlement, retaining assignment history, and moving inventory to `quarantined`.
- Transfer or Domain migration by preparing a target assignment and separate UUID graph while the source assignment is `pending_release`; source ownership closes only after verified target publication.
- Failed pre-publication assignment, lifecycle transition, or transfer restores the authoritative prior assignment state and keeps/re-enables the previous route.
- Read-only FusionPBX reconciliation and staff diagnostics from Phase 1 remain available.

## Safety boundaries

- Every mutation requires an inactive Portal identity context, FusionPBX `superadmin`, CSRF for POST, and its narrow DID permission.
- The Edge Function is server-only and requires the Mphone admin secret plus a valid enabled FusionPBX operator.
- Customer and Domain ownership is sourced from Customer Platform; FusionPBX number matching never grants authorization.
- New Fusion resources are disabled during preparation.
- Cutover disables the previous managed Destination/dialplan, enables the new graph, verifies it, and then moves Customer Platform's active-route reference.
- Generated resources use exact UUID ownership records. Existing unmanaged number collisions block publication.
- No global menu or permission reset was run.

## Files

- Customer Platform lifecycle migration: `/opt/supabase/supabase-project/volumes/db/init/mphone_simple_call_routing_phase2.sql`
- Internal service: `/opt/supabase/supabase-project/volumes/functions/mphone-call-routing-admin/index.ts`
- Portal endpoint: `app/portal/service/did_inventory.php`
- Fusion publisher: `app/portal/resources/simple_call_routing_publisher.php`
- Superadmin UI: `app/portal/spa/src/pages/dids/DidInventory.jsx`
- SQL lifecycle test: `/opt/supabase/supabase-project/volumes/db/init/tests/mphone_simple_call_routing_phase2_test.sql`
- Publisher integration test: `app/portal/resources/tests/simple_call_routing_phase2_publisher_test.php`
- Static/live contract test: `app/portal/resources/tests/simple_call_routing_phase2_self_test.php`

## Verification

- Phase 1 and Phase 2 migrations reapply successfully.
- Phase 1 SQL self-test passes.
- Phase 2 SQL self-test passes in a rolled-back transaction, including reserve, assignment preparation/publication/activation, stale ownership rejection, failed suspension restoration, and failed transfer restoration.
- Publisher integration test creates a disabled temporary route, verifies it, removes its exact UUID rows, and leaves no Destination behind.
- PHP lint passes.
- Internal inventory service returns current Customer/Domain and Customer Extension ownership options.
- SPA production build succeeds and emits the DID Inventory chunk.
- Served visual rendering was not inspected in a browser in this environment.

## Operational note

Users already signed in before the Phase 1 permission installation must sign out and sign in again. The local inventory remains empty; no real DID or live call route was created by deployment or tests.
