# Phase 3 — Basic Simple Routing Implementation

Status: implemented locally on 2026-08-31.

Phase 3 enables the first Customer routing writes. Only an active Workspace Owner can read or mutate this surface; staff DID lifecycle authority remains separate.

## Implemented

- Owner-only page at `/p/phone-numbers` with Phone Numbers and Extensions sections.
- Read-only inbound-number summary per Extension.
- Authorized outbound caller-ID selection per Extension.
- Editable Default answering group per active DID.
- Customer Platform ownership, assignment-state, management-mode, assignment-revision, management-revision, Extension ownership, Domain, and outbound-entitlement validation.
- A new `simple_direct` route version for every Save and Apply.
- Disabled Destination, dialplan, simultaneous Ring Group, and Ring Group membership preparation with exact UUID ownership records.
- Verified cutover through the Phase 1 publication primitive; the old managed graph is restored if pre-publication work fails.
- FusionPBX outbound caller-ID updates with pre-change snapshots and restoration on failed cutover.
- Persisted per-DID group membership in route `desired_state`; this is the authoritative inbound assignment source.
- Persisted per-Extension outbound caller-ID preferences in Customer Platform.
- Greeting and keypad behavior remain out of scope until Phase 4.

## Verification

- Phase 1, Phase 2, and Phase 3 SQL transaction tests pass and roll back their fixtures.
- The publisher integration test creates and removes its exact Destination, dialplan, Ring Group, and membership rows.
- Customer routing view returns HTTP 200 for a real active Owner context.
- PHP lint, JSON parsing, static contract tests, and the SPA production build pass.
- The built `SimpleCallRouting` chunk and `/p/phone-numbers` are served by the configured TLS virtual host.
- No real DID was created and no test route remains.

## Operational boundary

Customer Owners cannot reserve, assign, suspend, release, transfer, or take over a DID. Non-Owner workspace roles receive HTTP 403 from the endpoint and are independently rejected by Customer Platform.
