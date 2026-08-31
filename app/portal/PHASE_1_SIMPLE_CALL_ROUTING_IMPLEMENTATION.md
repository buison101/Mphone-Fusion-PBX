# Phase 1 — DID and Routing-Publication Foundation Implementation

Status: implemented locally on 2026-08-31.

Scope: Phase 1 of `PORTAL_SIMPLE_CALL_ROUTING_PLAN.md`. This phase installs the Customer Platform state, internal service boundary, read-only FusionPBX reconciliation, narrow staff permissions, operation locking/idempotency, and atomic route-publication state transition. It does not expose Customer routing writes or create a live DID route.

## 1. Implemented components

### Customer Platform migration

Migration:

```text
/opt/supabase/supabase-project/volumes/db/init/mphone_simple_call_routing_phase1.sql
```

It creates:

- `mphone_dids`
- `mphone_did_assignments`
- `mphone_did_outbound_entitlements`
- `mphone_did_route_versions`
- `mphone_did_routing_management`
- `mphone_did_route_resources`
- `mphone_did_operations`
- `mphone_did_audit_events`
- `mphone_did_reconciliation_exceptions`

Database constraints enforce canonical E.164 identity, one open assignment per DID, one current outbound entitlement per assignment, one published route per assignment, immutable published history, exact generated-resource UUID ownership, and valid active-route/snapshot references.

### Operation and publication functions

- `mphone_did_begin_operation` locks the DID row, validates expected assignment and management revisions, creates an audit event, and replays the same operation key only when its request fingerprint matches.
- `mphone_did_finish_operation` records a terminal result idempotently and appends the completion audit event.
- `mphone_did_advance_route_version` enforces `draft -> generated -> validated` or failure transitions.
- `mphone_did_publish_route` accepts only a validated and externally verified route, supersedes the previous published version, moves the single active-route pointer, and finishes the operation in one database transaction.

FusionPBX resource writes and XML/cache verification occur outside the Customer Platform transaction. The active-route reference changes only after the caller submits a successful verification result. Failed generation or verification therefore leaves the existing active reference unchanged.

### Internal service

Edge Function:

```text
/opt/supabase/supabase-project/volumes/functions/mphone-call-routing-admin/index.ts
```

Supported Phase 1 actions:

- `foundation_status`
- `begin_operation`
- `finish_operation`
- `advance_route`
- `publish_route`
- `reconcile_fusion_inventory`

The service requires the server-side Mphone admin secret, a valid enabled FusionPBX operator, and the trusted `actor_superadmin` assertion supplied by the PHP bridge. It is not a browser API. Request payloads are canonically hashed server-side for idempotency comparison.

PHP bridge:

```text
app/portal/resources/call_routing_platform.php
```

The public wrapper requires an explicit FusionPBX permission before forwarding a request. The lower-level transport is used only by CLI code after independently proving an active `superadmin` operator.

### Read-only reconciliation

CLI:

```sh
php app/portal/resources/reconcile_call_routing.php
```

The Customer Platform Fusion reader received SELECT-only access to Destination, dialplan, Ring Group, IVR, and recording execution tables. Reconciliation compares known canonical DIDs to observed Destinations and records unmanaged candidates or duplicate-number conflicts. It never creates an assignment, adopts a Destination, or edits FusionPBX.

### Permissions

The following permissions are declared and installed only for `superadmin`:

```text
did_inventory_view
did_inventory_manage
did_assign
did_suspend
did_release
did_transfer
call_routing_takeover
call_routing_publish_advanced
call_routing_cancel_transition
call_routing_release
call_routing_view_snapshot
```

They were installed with the targeted script:

```text
app/portal/resources/database/postgresql/simple_call_routing_phase1_permissions.sql
```

The global menu and permission reset commands were not used.

## 2. Backups

Verified custom-format backups were created before database mutation:

```text
/var/backups/mphone-routing-phase1/pre-phase1-20260831.dump
/var/backups/mphone-routing-phase1/fusion-permissions-pre-phase1-20260831.dump
```

The first archive contains Customer, tenant, Customer Extension ownership, and Extension assignment data. The second contains FusionPBX permission and group-permission tables. `pg_restore -l` confirmed the required table-data entries.

## 3. Verification performed

- Customer Platform migration applied successfully three times, proving repeatable DDL behavior.
- SQL transaction self-test passed and rolled back all fixtures.
- Duplicate assignment and entitlement constraints passed.
- Invalid E.164 rejection passed.
- Published route immutability passed.
- Idempotent operation replay and conflicting-key rejection passed.
- Stale assignment revision rejection passed.
- Route generation, validation, verified publication, previous-version supersession, and active-pointer cutover passed.
- PHP syntax checks passed for every new or changed PHP file.
- Portal Phase 1 self-test passed.
- Internal service returns `401` without its secret and `403` for an invalid FusionPBX operator.
- Internal foundation status returns `200` and explicitly reports `customer_writes_enabled: false`.
- Read-only reconciliation completed with `dids=0 destinations=0 matches=0` on the local VM.
- All eleven permissions exist once, map to `superadmin`, and have no `admin` or `user` mapping.

## 4. Current live state

The new foundation tables are empty. No DID inventory row, assignment, entitlement, route version, generated FusionPBX resource, or Customer-visible control was created. Existing call paths are unchanged.

Already logged-in FusionPBX sessions do not see the newly installed permissions until the user signs out and signs in again.

## 5. Phase 2 entry conditions

Phase 2 may now implement Mphone staff DID inventory and lifecycle operations using this service boundary. It must not write assignment state directly. Initial route generation requires a FusionPBX-side writer that prepares new UUIDs, validates the complete generated graph/XML, and calls `publish_route` only after verification.

The production provider adapter remains intentionally unresolved. Pilot inventory may use explicit staff-maintained provider state, as allowed by the Phase 0 specification.
