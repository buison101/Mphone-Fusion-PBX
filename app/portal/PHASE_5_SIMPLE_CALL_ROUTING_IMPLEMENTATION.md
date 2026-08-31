# Phase 5 — Direct Advanced Takeover and Basic Reset

Status: implemented locally on 2026-08-31.

## Direct takeover

- Authorized Mphone staff can move an active DID from `portal_simple` directly to `mphone_advanced`.
- The management revision changes atomically, stale Customer forms are rejected, and the current live FusionPBX route remains available for direct staff editing.
- No parallel Advanced draft, Customer history UI, or Customer rollback workflow is created.

## Release to Basic

- Staff inspect the live DID entry point and choose one or more active Customer-owned Extensions for the new Default answering group.
- Automatic release requires exactly one enabled Destination for the DID and a Dialplan referenced by only that Destination.
- A new versioned Basic route is prepared disabled, verified, cut over, verified enabled, and published before management returns to `portal_simple`.
- Failure restores the Advanced entry point and returns management to `mphone_advanced`.

## Cleanup boundary

- After successful release, the exact Advanced DID Destination and dedicated entry Dialplan are deleted, together with old Portal-owned Basic technical resources.
- Manual IVRs, queues, time conditions, recordings, and ring groups are never inferred as owned and are not automatically deleted.
- Direct Dialplan actions are shown as staff cleanup suggestions. This is intentionally not a recursive FusionPBX dependency graph.
- Resource ownership history remains in Supabase and deleted generated objects are marked `missing`.
