# Phase 0 — Simple Call Routing Discovery and Specification Freeze

Status: implementation-ready foundation specification with two explicitly deferred catalogue decisions.

Date: 2026-08-31.

Scope: Phase 0 of `PORTAL_SIMPLE_CALL_ROUTING_PLAN.md`. This phase is read-only with respect to live telephony and Customer data. No Destination, dialplan, Ring Group, IVR, recording, DID assignment, or entitlement was created or changed.

## 1. Decision summary

The implementation boundary is:

```text
Customer Platform                         FusionPBX
-----------------                         ---------
Customer and Membership authority         Domain and Extension execution state
Customer -> Extension ownership            Destination, dialplan, Ring Group, IVR
DID inventory and assignment authority --> generated route execution resources
Routing desired state and audit         --> generated resource references/fingerprints
```

The Customer Platform is authoritative for Customer identity, Membership role, Customer-owned Extensions, DID inventory, DID assignment, entitlements, routing-management state, route versions, and audit history. FusionPBX is authoritative for whether referenced telephony resources currently exist and for executing the published route.

`domain_uuid`, a matching Destination number, an Extension caller-ID value, or provider data must never create Customer authorization.

Phase 1 must implement the Customer Platform records and one server-side service boundary before any Customer routing write is enabled. FusionPBX controllers, Portal endpoints, provider jobs, CLI tools, and emergency tools must call that service; they must not update active assignment or active-route fields directly.

## 2. Discovery evidence

### 2.1 Customer and Extension authority

The deployed Customer model already defines `mphone_customer_extensions` as the authoritative Customer-to-Extension ownership source. Identity assignments separately provide `can_use` and `can_manage` and do not replace Customer ownership.

Routing lookups therefore use:

```text
Customer -> active mphone_customer_extensions ownership
         -> enabled FusionPBX Extension with the same extension_uuid and domain_uuid
```

The exact Customer membership role `owner` is required for Customer mutations. An Extension is selectable for a DID answering group only when it is actively owned by the Customer and valid in the assignment's active Domain. Identity-level `can_use` and `can_manage` remain relevant to user/device features but do not narrow the Owner's Customer-wide routing catalogue.

### 2.2 Local FusionPBX inventory

Read-only inspection of the `fusionpbx` PostgreSQL database found:

| Resource | Count | Domains represented |
|---|---:|---:|
| Domains | 3 | 3 |
| Extensions | 9 | 1 |
| Destinations | 0 | 0 |
| Ring Groups | 0 | 0 |
| IVR menus | 0 | 0 |
| Recordings | 0 | 0 |

No normalized duplicate Destination number exists in this VM because the Destination table is empty. This makes the VM suitable for a greenfield pilot, but it is not evidence that another installation can safely adopt an existing Destination.

Before a production migration, the same inventory report must run against the target database and classify every candidate DID and referenced resource as `unmanaged`, `conflict`, or explicitly imported by an authorized operation.

### 2.3 FusionPBX execution resources

The existing execution tables are suitable targets but do not contain Customer ownership:

- `v_destinations` and its generated `v_dialplans`/`v_dialplan_details` route the inbound DID.
- `v_ring_groups` and `v_ring_group_destinations` represent simultaneous answering members.
- `v_recordings` supplies greeting media metadata.
- `v_ivr_menus` and `v_ivr_menu_options` represent the single-level keypad route.
- `v_extensions` stores the applied outbound caller-ID value.

Generated-resource ownership must be recorded by UUID in Customer Platform route versions. Names, descriptions, number matching, and UUID presence alone are not ownership markers.

## 3. Authoritative lookups

### 3.1 Authorized inbound DIDs

```text
active workspace Customer
  -> active DID assignment
  -> inventory DID with inbound capability
  -> provider service state allowed by policy
  -> assignment Domain matches the active workspace tenant
```

Only an `active` assignment is customer-visible. A `pending_assignment` may be operated on by Mphone staff but is not returned by Customer Phone Numbers endpoints.

### 3.2 Managed Extensions

```text
active workspace Customer
  -> active mphone_customer_extensions ownership
  -> enabled v_extensions row
  -> matching assignment domain_uuid
```

Missing, disabled, or Domain-mismatched Extensions are reconciliation exceptions and cannot be added to a new route version.

### 3.3 Authorized outbound caller IDs

An outbound number is selectable only when all of the following are true:

- The DID has an active assignment to the same Customer and Domain.
- The inventory capability includes outbound caller ID.
- A separate active outbound entitlement exists for the assignment.
- Inventory, provider service, assignment, and suspension policies permit use.

Existing values in `v_extensions.outbound_caller_id_number` are observed execution state, not entitlement.

### 3.4 Authorized destination groups

No authoritative Customer-owned extension-group model was found in the current repository or local database. FusionPBX authorization groups are not telephony destination groups and must not be reused.

Phase 3 can implement the per-DID Default answering group because its membership is new Portal-owned desired state. Keypad targets in Phase 4B must initially be limited to authorized Extensions unless a separate Customer-owned reusable destination-group catalogue is approved and implemented. This does not block Phases 1 through 4A.

## 4. Required Customer Platform records

Final SQL naming may follow the Customer Platform migration convention, but the following logical records and constraints are frozen.

### 4.1 `mphone_dids`

- `did_uuid` primary key.
- `canonical_e164` unique, immutable identity after validation.
- `display_number`, country/numbering-plan metadata, and optional provider reference.
- Independent `inventory_status` and `provider_service_status`.
- Capability flags, including inbound and outbound caller ID.
- Audit actor and timestamps.

Canonicalization accepts input only after an explicit country/numbering-plan rule produces a valid E.164 value. Stripping punctuation alone is not sufficient normalization.

### 4.2 `mphone_did_assignments`

- Assignment UUID, DID UUID, Customer UUID, Domain UUID, status, and monotonically increasing assignment revision.
- Lifecycle timestamps/actors and optional transfer linkage.
- Inbound entitlement status.
- No update of Customer or Domain ownership in place; transfer creates a replacement assignment.
- A partial unique constraint permits at most one assignment per DID whose status is `pending_assignment`, `active`, or `pending_release`.

The uniqueness constraint is the database backstop; the lifecycle service must also lock the DID row before checking or changing assignment state.

### 4.3 `mphone_did_outbound_entitlements`

- Entitlement UUID and assignment UUID.
- Status, effective interval, reason, revision, actors, and timestamps.
- At most one currently effective entitlement per assignment.
- Entitlement becomes unusable immediately when its assignment is not active, even if the entitlement row has not yet been reconciled.

### 4.4 `mphone_did_routing_management`

- One row per assignment.
- Management mode and transition state.
- Monotonic management revision.
- Nullable active route-version UUID.
- Last applied and last observed fingerprints.
- Last known-good Simple snapshot reference.

Only the transition/publication service may update mode, revision, transition state, active route, or snapshot reference.

### 4.5 Route versions and desired state

Each immutable route version contains:

- Route-version UUID, assignment UUID, management revision, version number, route type, status, and source version.
- Default answering membership referencing Customer-owned Extension UUIDs.
- Greeting configuration and recording UUID where applicable.
- Keypad digit mappings where applicable.
- Generated Destination, dialplan, Ring Group, recording, IVR, and option UUID references.
- Proposed, generated, validated, published, failed, and superseded timestamps/outcomes.
- Desired-state fingerprint and observed generated-resource fingerprint.

Mutable drafts may be edited only while unpublished. A published version is immutable; a change creates a new version.

### 4.6 Operations and audit

Every lifecycle or publication request stores a caller-supplied idempotency key unique within its operation scope. The audit event records actor Identity/Fusion user, interface, reason, Customer, Domain, DID, assignment and management revisions, before/after state, route references, validation results, outcome, and timestamps.

Audit payloads must not contain SIP credentials, session tokens, provider secrets, or recording media.

## 5. State machines

### 5.1 Inventory

```text
available -> reserved -> quarantined -> available
                 |             |
                 +----------> retired
```

Assignment eligibility normally requires `reserved`. Provider state remains independent.

### 5.2 Provider service

```text
provisioning -> active -> suspended -> active
                    |          |
                    +-> porting_out -> disconnected
```

Allowed transitions are provider-adapter policy. Provider synchronization may change provider state but never assignment ownership or entitlement.

### 5.3 Assignment

```text
pending_assignment -> active -> pending_release -> released
          |              |
          |              +-> suspended -> active
          +-> failed
```

`suspended` is reversible service state associated with the active assignment and must not be represented by deleting or releasing it. While suspended, Customer routing writes and outbound caller-ID use are rejected. The inbound route must publish an explicit service-unavailable announcement or rejection policy; silently retaining the Customer route is prohibited.

### 5.4 Routing management

```text
portal_simple -> transitioning_to_advanced -> mphone_advanced
      ^                                           |
      +------- transitioning_to_simple <----------+

unmanaged
```

Transition failure returns to the mode whose route remained active. `unmanaged` cannot transition through Customer actions and requires explicit Mphone classification/import.

### 5.5 Route version

```text
draft -> generated -> validated -> published -> superseded
   |         |           |
   +---------+-----------+-> failed
```

Publication changes the single active-route reference only after validation. Failure before or after XML/cache refresh retains or restores the last verified active reference.

## 6. Service boundaries

### 6.1 DID lifecycle service

Required operations:

```text
reserve(did_uuid, expected_inventory_revision, operation_key, reason)
assign(did_uuid, customer_uuid, domain_uuid, initial_mode, expected_revision, operation_key, reason)
suspend(did_uuid, expected_assignment_revision, operation_key, reason)
resume(did_uuid, expected_assignment_revision, operation_key, reason)
transfer(did_uuid, target_customer_uuid, target_domain_uuid, expected_revision, operation_key, reason)
release(did_uuid, expected_assignment_revision, operation_key, reason)
```

Every operation locks the DID, revalidates state and revision, and delegates route preparation/publication where required. Assignment activation is the final step after successful initial-route verification.

### 6.2 Route publication service

Required operations:

```text
prepare(route_version_uuid, expected_management_revision)
validate(route_version_uuid, expected_management_revision)
publish(route_version_uuid, expected_management_revision, operation_key)
verify(route_version_uuid)
rollback(did_uuid, failed_version_uuid, expected_management_revision, operation_key)
```

Phase 1 must define an atomic database cutover boundary and an idempotent recovery procedure for failures occurring between FusionPBX resource writes, XML/cache refresh, verification, and active-route update.

### 6.3 Management transition service

The contract remains:

```text
takeover(did_uuid, expected_revision, reason)
publish_advanced(did_uuid, draft_version_uuid, expected_revision)
cancel_takeover(did_uuid, expected_revision, reason)
release_to_simple(did_uuid, simple_version_uuid, expected_revision, reason)
```

The Phase 1 data model and enforcement are required immediately; the staff-facing Advanced workflow may wait until Phase 5.

## 7. Managed-resource and conflict policy

- A FusionPBX resource is Portal-managed only when an active or historical route version records its exact UUID and expected fingerprint.
- A matching number, name, description, app UUID, or Domain is never enough to adopt a resource.
- A Destination number collision blocks assignment/publication and creates a reconciliation exception.
- A missing recorded UUID, changed fingerprint, unexpected dependent UUID, or mismatched Domain blocks automatic repair and requires staff review.
- Simple and Advanced graphs use different UUIDs. A transition publishes a different graph rather than editing the active graph in place.
- Deletion is not part of normal rollback. Failed and superseded graphs are disabled or retained according to retention policy until safe cleanup is explicitly authorized.

Fingerprint inputs must be canonical, ordered representations of routing-relevant fields and child rows. Audit fields and timestamps are excluded.

## 8. Migration, backup, and rollback

### 8.1 Before Phase 1 migration

- Back up every new Customer Platform table and all affected FusionPBX tables.
- For FusionPBX, the minimum set is `v_destinations`, `v_dialplans`, `v_dialplan_details`, `v_ring_groups`, `v_ring_group_destinations`, `v_ivr_menus`, `v_ivr_menu_options`, `v_recordings`, and `v_extensions`.
- Record row counts and a checksum manifest, and restore the backup into a temporary database to prove it is readable.
- Back up the Customer Platform ownership, assignment, entitlement, route-version, operation, audit, and reconciliation tables once created.

### 8.2 Import policy

- Inventory import creates DID identity only; it does not create assignment or ownership.
- Existing Destinations are reported as candidates and remain `unmanaged`.
- Adoption requires an explicit Mphone operation, verified Customer evidence, expected fingerprints, and a new managed route version.
- Ambiguous number normalization, duplicate canonical values, conflicting Domains, or unknown provider state blocks activation.

### 8.3 Rollback policy

- Schema rollback disables new services and UI first; it does not delete audit or assignment history.
- Route rollback republishes the last verified route version and verifies it before marking the failed version inactive.
- Assignment failure before activation leaves the assignment non-visible and recoverable by the same idempotency key.
- A migration down-script must not remove generated live resources until a restore rehearsal proves the previous route is active.

## 9. Phase 0 fixtures and gates

The Phase 1 automated fixture set must include:

- Two Customers in one Domain.
- At least two Extensions owned by Customer A and one by Customer B.
- One available DID, one active DID, one quarantined DID, and one unmanaged/conflicting candidate.
- Concurrent assignment attempts by both Customers.
- A stale assignment revision and stale management revision.
- Failed generation, failed validation, failed XML/cache refresh, and failed post-publication verification.
- An idempotent retry using the same operation key.
- Cross-Customer Extension and outbound caller-ID attempts.
- Suspension, resume, release, quarantine, transfer, and Domain migration.
- Drift in a generated Ring Group or Destination fingerprint.

Phase 1 may start when its migration and service tests encode these invariants. Phase 2 may not activate a real assignment until backup restore, failed-publication recovery, and idempotent retry have passed locally.

## 10. Deferred decisions that do not block Phase 1

1. **Provider adapter and production provider-state source.** The local VM has no DID/provider inventory. Phase 1 must use an adapter boundary and permit an explicit staff-maintained provider state for pilot data; production activation requires selecting the real provider source.
2. **Reusable Customer-owned destination groups.** No authoritative model exists. Phase 4B must expose Extension targets only until that catalogue is designed. The per-DID Default answering group is not affected.

These decisions block only the corresponding provider automation and reusable keypad-group capability. They do not justify weakening Customer assignment, entitlement, or managed-resource invariants.

## 11. Phase 0 outcome

Phase 0 is complete for starting the Phase 1 foundation. The local discovery establishes a greenfield routing environment, identifies the existing Customer Extension ownership authority, freezes the minimum state and service contracts, and records the two capabilities that must remain adapter-gated or deferred.

No live data or call path was changed during this phase.
