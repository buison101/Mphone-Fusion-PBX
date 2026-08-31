# Portal Simple Call Routing Plan

## 1. Purpose

Provide Customer Owners with a simple self-service workflow for configuring normal PBX call routing without exposing FusionPBX dialplans, destinations, ring groups, or IVR internals.

The feature covers:

- Selecting the Default answering-group members for each authorized inbound number.
- Selecting one authorized outbound caller ID for each extension.
- Automatically ringing members of the same Default answering group simultaneously.
- Configuring a greeting for each authorized phone number.
- Optionally enabling a simple, single-level `0-9` keypad menu.
- Keeping advanced routing under Mphone staff control.

This document is a plan only. It does not authorize or include implementation changes.

## 2. Product Principles

1. The phone-number screen is the single editable source of default inbound membership, greeting, keypad behavior, and fallback for that DID.
2. The extension screen shows inbound numbers as a read-only summary and controls only the extension's authorized default outbound caller ID.
3. An inbound number has exactly one active routing mode at a time.
4. Outbound caller ID is independent of inbound routing, greetings, and keypad menus.
5. Customers select only resources explicitly authorized for their Customer.
6. Only the Customer membership role `owner` may modify these settings in the Portal.
7. Advanced or manually managed call flows must never be overwritten by the Portal.
8. Portal configuration expresses business intent; a server-side synchronizer translates it into FusionPBX resources.
9. Routing management mode belongs to each inbound DID, not to an Extension or the whole Customer.
10. A DID has exactly one management owner and one active route at a time.
11. Customer Owners may never move an advanced DID back to simple management; only authorized Mphone staff may release it.
12. The Portal Superadmin interface is the control plane for routing-management ownership, transitions, publication, and rollback.
13. FusionPBX may be used by Mphone staff to edit an Advanced draft, but a FusionPBX edit or role never changes the DID management mode by itself.
14. Portal Superadmin, support CLI, and emergency tooling must call the same server-side transition service; no interface may update management state or the active-route reference directly.

## 3. MVP User Experience

### 3.1 Extensions screen

Example:

```text
101 — Nguyen Van An

Receives calls from:
02873001234
02873005678
(read only)

Default outbound number:
[02873001234 v]
```

Rules:

- An extension may receive calls from multiple authorized inbound numbers, but this membership is edited only on the Phone Numbers screen.
- The inbound-number list is derived from the default answering groups and is read-only on this screen.
- An extension has one default outbound caller ID.
- Multiple extensions may share the same outbound caller ID.
- Outbound numbers are selected from server-provided options; free-text entry is not allowed.
- Non-Owner roles cannot modify these fields.

### 3.2 Phone Numbers screen

Example:

```text
02873001234

Default answering group:
[101 Nguyen Van An] [102 Tran Van Binh] [+ Add]

Greeting:              [On]
Greeting recording:    [Select or upload]

Allow keypad selection:[On]

0 -> [Reception v]
1 -> [Sales group v]
2 -> [Support group v]

Fallback for no input or invalid input:
Default answering group: 101, 102

Call flow summary:
Greeting -> wait for digit
            |- 0 -> Reception
            |- 1 -> Sales group
            |- 2 -> Support group
            `- no/invalid input -> 101, 102
```

The Default answering group is the single editable source for inbound membership. Multiple Extensions in this group ring simultaneously. The same group is also the fallback for greeting and keypad flows.

The fallback is fixed to the Default answering group in simple mode; customers do not configure an independent arbitrary fallback destination. The UI presents this behavior explicitly so the resulting route is predictable.

The Call flow summary is derived by the server from the proposed configuration. It shows the effective direct, greeting-only, or keypad route before **Save and Apply**, without exposing FusionPBX resource names.

When the DID is not in `portal_simple`, the Customer Phone Numbers screen must not show the suspended Simple values as though they were active. Greeting, recording, answering-group, and keypad controls are hidden and replaced by the management message below. The screen may show a server-derived, customer-safe summary of the active Advanced route when one is explicitly available. Internal FusionPBX names, UUIDs, and the retained Simple snapshot are not customer-visible. The browser must not offer a control for returning an Advanced DID to Simple mode.

The customer-facing feature name should be **Greeting & Keypad**, not IVR.

## 4. Call Routing Behavior

### 4.1 Direct ringing

```text
DID -> Default answering group, ringing all members simultaneously
```

### 4.2 Greeting without keypad

```text
DID -> play greeting -> Default answering group
```

### 4.3 Greeting with keypad

```text
DID -> play greeting and collect a digit
      |- valid digit -> configured extension or group
      |- no digit    -> Default answering group
      `- invalid     -> replay once -> Default answering group
```

When keypad mode is enabled, members of the Default answering group do not ring immediately. They remain the fallback for the no-input and final invalid-input paths.

Outbound caller ID settings are unaffected by these modes.

## 5. Simple Keypad Boundaries

To prevent this feature from becoming a general dialplan builder:

- Only one keypad level is supported.
- Only digits `0-9` are supported.
- Each digit has at most one destination.
- A destination must be an authorized extension or authorized extension group belonging to the active Customer.
- A digit cannot point to another keypad menu or IVR.
- External-number destinations are not supported in simple mode.
- Business hours, holidays, queues, conditional routing, and multi-level IVRs are excluded.
- Invalid input is replayed at most once, then routed to the no-input destination.
- No input and final invalid input route to the current Default answering group.
- Keypad mode cannot be enabled without a valid greeting and a valid fallback route.

Anything outside these boundaries is an Mphone-managed advanced scenario.

## 6. Authorization and Tenant Isolation

### 6.1 Owner-only writes

Every write endpoint must require the exact Customer membership role:

```text
portal_identity.membership.role = owner
```

`customer_admin`, `billing_admin`, extension users, and FusionPBX `admin` are not equivalent to Customer Owner for this feature.

React control visibility is only a user-experience measure. Authorization must be enforced on every server-side write.

### 6.2 Required server-side checks

Every read and write must be scoped by the authenticated session and verify:

- A valid Portal identity and active Customer workspace.
- Exact Owner role for mutations.
- The session `domain_uuid`.
- The session `customer_uuid`.
- DID ownership or entitlement for the active Customer.
- Extension ownership or management entitlement for the active Customer.
- Outbound caller ID entitlement.
- Recording and destination-group ownership.
- Cross-Customer UUIDs are rejected even when they exist in the same Domain.

The browser must not be trusted to supply authoritative `domain_uuid` or `customer_uuid` values.

## 7. Discovery Before Implementation

Before designing the final schema or endpoints, establish the authoritative source for:

1. DIDs assigned to a Customer.
2. Extensions managed by a Customer, not merely extensions assigned to the signed-in user.
3. Numbers authorized as outbound caller IDs.
4. Extension groups that may be exposed as keypad destinations.
5. Existing advanced or manually managed routes.

Do not assume that all resources sharing a `domain_uuid` belong to the same Customer.

The discovery phase must produce reliable internal lookups for:

```text
Customer -> authorized inbound DIDs
Customer -> managed extensions
Customer -> authorized outbound caller IDs
Customer -> authorized destination groups
```

### 7.1 DID inventory and assignment authority

The Portal must manage DIDs as a central inventory with explicit Customer assignments. A FusionPBX Destination, a matching number in an Extension, a shared `domain_uuid`, or a carrier record is not proof that a Customer owns or may manage a DID.

The authoritative responsibilities are:

- The Portal DID inventory is authoritative for numbers managed by Mphone and their service lifecycle.
- The active DID assignment is authoritative for which Customer and Domain may use a number.
- A separate outbound caller-ID entitlement determines whether an assigned DID may be selected for outbound presentation.
- FusionPBX Destinations and generated dialplans are execution state derived from an active assignment and routing configuration.
- Provider or carrier data may verify provisioning status, but does not grant Portal authorization by itself.

The conceptual relationship is:

```text
DID inventory -> active Customer assignment -> routing management -> active FusionPBX route
                                      `------> outbound caller-ID entitlement
```

A DID may have at most one active Customer assignment. Shared-number or reseller scenarios that require multiple active Customers are Advanced products and must not weaken this invariant in the Simple model.

### 7.2 DID inventory data

Each inventory record needs at least:

- Stable `did_uuid` independent of a FusionPBX Destination UUID.
- Canonical E.164 number and a separate display format.
- Country or numbering-plan metadata.
- Provider reference where applicable.
- Service status and supported capabilities, including inbound, outbound caller ID, SMS, or other future services.
- Insert/update actor and timestamps.

Canonical number uniqueness must be enforced after normalization. Display formatting must never be used for identity, uniqueness, entitlement, or routing comparisons.

Inventory allocation states and provider service states must remain separate. Recommended inventory states are:

```text
available
reserved
quarantined
retired
```

Recommended provider service states are:

```text
provisioning
active
suspended
porting_out
disconnected
```

Inventory status, provider service status, Customer assignment status, and routing management mode are independent state machines. For example, a DID may be inventory `reserved`, provider service `active`, assignment `pending_assignment`, and routing mode `portal_simple` while its initial route is being prepared.

### 7.3 Customer assignment records

Assignment history must be retained rather than replacing `customer_uuid` in place. Each assignment needs:

- Assignment UUID, DID UUID, Customer UUID, and active Domain UUID.
- Assignment status and revision.
- Assigned/reserved/released timestamps and actors.
- Effective dates where provider provisioning is asynchronous.
- Optional transfer reference linking the previous and replacement assignments.
- Inbound entitlement status.
- Outbound caller-ID entitlement status or a reference to a separate entitlement record.

Recommended assignment states are:

```text
pending_assignment
active
pending_release
released
```

`unassigned` is the absence of an active or pending assignment, not a historical assignment row that must be created.

The database must enforce no more than one active or activation-pending assignment per DID. All routing and caller-ID mutations must revalidate the active assignment immediately before writing.

### 7.4 Assigning a DID to a Customer

DID assignment is an Mphone staff operation initiated from Portal Superadmin. A Customer Owner cannot reserve, assign, transfer, release, or reclaim a DID.

The assignment workflow is:

1. Require a narrow DID-assignment permission and an explicit target Customer and Domain.
2. Lock the DID inventory record and revalidate that it has no conflicting assignment or transition.
3. Reserve the DID and create a `pending_assignment` record with a new assignment revision.
4. Select the initial routing mode: `portal_simple` or `mphone_advanced`.
5. Create a new routing-management record and a new route draft. Never adopt a Destination merely because its number matches.
6. Validate provider/service state, Customer and Domain mappings, Destination uniqueness, generated resources, and XML.
7. Publish the route through the same active-route mechanism used by routing transitions.
8. Only after successful publication set the assignment to `active` and expose the DID to the Customer Portal.
9. Record the actor, reason, before/after state, assignment revision, route references, and validation result in the audit trail.

If provisioning or route publication fails, the DID must not appear to the Customer as active. Retry must be idempotent and must not create a second assignment, Destination, or route graph.

### 7.5 Suspending, releasing, and quarantining a DID

Releasing a DID is a controlled workflow, not deletion of an assignment row:

1. Lock the DID and change the assignment to `pending_release`.
2. Reject subsequent Customer routing mutations and revoke its outbound caller-ID entitlement.
3. Preserve the active routing configuration, generated-resource references, and audit snapshot according to retention policy.
4. Disable or replace the inbound route according to the approved service policy and verify the published result.
5. Close the assignment as `released`; do not erase its history.
6. Move the inventory record to `quarantined` for a configured cooling-off period before it can become `available` again.

Suspension must be reversible and distinct from release. The plan must define inbound behavior during suspension, such as rejection or a service announcement, and must never silently leave the Customer's previous route reachable.

### 7.6 Transferring a DID between Customers or Domains

A transfer must close the source assignment and create a new target assignment. Updating `customer_uuid` or `domain_uuid` in place is prohibited.

The transfer service must:

- Lock the DID and both assignment contexts.
- Block source-Customer changes and revoke source outbound caller-ID entitlement.
- Preserve the source route and assignment snapshot for audit and recovery.
- Create new target routing resources with new UUIDs; source Simple or Advanced resources must not be reused by the target Customer.
- Validate and publish the target route before activating the target assignment.
- Close the source assignment only according to the defined cutover boundary.
- Provide rollback behavior that never produces two active Customer assignments.

A Domain migration for the same Customer follows the same prepare-and-publish pattern. It must not update `domain_uuid` in place when doing so could interrupt calls or create cross-Domain resource references.

### 7.7 DID inventory permissions and staff interface

Use narrow Mphone staff permissions such as:

```text
did_inventory_view
did_inventory_manage
did_assign
did_suspend
did_release
did_transfer
```

A FusionPBX `admin` or `superadmin` role does not grant these permissions automatically. Portal Superadmin should provide:

- A DID inventory showing normalized/display number, provider, service status, Customer, Domain, assignment status, and routing mode.
- A Customer Phone Numbers tab showing current assignments and actions allowed by state and permission.
- Assignment history and linked routing/audit events.
- Actions to reserve, assign, suspend, resume, transfer, release, and open routing management.

Portal, CLI, import, provider synchronization, and emergency tooling must call the same server-side DID lifecycle service. Direct changes to assignment ownership or lifecycle fields are unsupported.

## 8. Configuration Data Model

The Portal should retain business-level desired state rather than attempting to reconstruct it exclusively from generated dialplans.

The design needs records for:

- DID inventory, normalized-number identity, provider reference, capabilities, and service lifecycle.
- Historical Customer assignments with an enforced single active assignment per DID.
- Inbound and outbound caller-ID entitlements associated with the active assignment.
- Per-DID Default answering-group membership.
- Default outbound caller ID per extension.
- Per-DID routing mode.
- Per-DID greeting and recording reference.
- Per-DID digit-to-destination mappings.
- Generated FusionPBX resource UUIDs.
- Management mode and ownership.
- Management revision, transition state, and the single active-route reference.
- The last applied and last observed fingerprints used for conflict detection.
- A recoverable snapshot of the last active simple configuration.
- Configuration version, status, and audit history.

All tenant-owned records must include:

- `domain_uuid`
- `customer_uuid`
- Object UUID
- Insert/update user and timestamps
- Enabled or lifecycle status
- Configuration version where applicable

Final table and field names will be selected after discovery of the existing Customer entitlement model.

## 9. FusionPBX Translation

### 9.1 Inbound membership

- Read the Default answering-group membership for the DID.
- Create or update a simultaneous Ring Group for each Portal-managed DID.
- Prefer retaining a Ring Group even when it has one member, so membership changes do not require changing the destination type.
- Point the DID Destination to the managed routing entry.

### 9.2 Greeting

- Use a validated recording belonging to the same Customer and Domain.
- Insert greeting playback before the managed Ring Group.
- Disabling the greeting restores the direct Ring Group route.

### 9.3 Keypad

- Create or update a managed, single-level FusionPBX IVR.
- Map digits only to authorized extension or group destinations.
- Route timeout/no input and final invalid input to the Ring Group generated from the current Default answering group.
- Point the DID Destination to the managed IVR.
- Disabling keypad mode restores greeting-only or direct routing.

### 9.4 Outbound caller ID

- Update the extension's outbound caller ID using only an authorized value.
- Never trust a caller ID value supplied by a SIP client or arbitrary browser input.

## 10. Greeting Recording Management

The Portal should expose a narrow Owner-only recording workflow using existing FusionPBX recording facilities where appropriate.

Requirements:

- Accept only approved media formats.
- Enforce file-size and duration limits.
- Inspect actual media type instead of trusting the filename extension.
- Normalize audio to a FreeSWITCH-compatible format.
- Generate server-side filenames and prevent path injection.
- Scope recordings by Domain and Customer.
- Allow preview before applying.
- Prevent deletion while a recording is referenced.
- Record upload, replacement, and deletion in the audit trail.

The first release may support upload and preview only. Browser recording can follow later.

## 11. Managed and Advanced Modes

Management mode is assigned per DID. It is not assigned to an Extension or to the whole Customer. An Extension may therefore receive calls from both a simple DID and a different advanced DID without creating shared ownership.

Each DID needs an explicit management state:

- `portal_simple`: the Portal synchronizer may manage the call flow.
- `transitioning_to_advanced`: Portal writes are locked while Mphone prepares and publishes a separate advanced route.
- `mphone_advanced`: Mphone staff owns the call flow; the Portal is read-only.
- `transitioning_to_simple`: Portal writes remain locked while Mphone prepares and validates a Simple route for release.
- `unmanaged`: existing configuration is visible as unavailable for Portal editing.

The ownership rules are:

- In `portal_simple`, the synchronizer exclusively owns the generated Destination routing entry, Ring Group, greeting flow, IVR, and their generated dialplans for that DID.
- In `mphone_advanced`, Mphone exclusively owns the active call flow and the synchronizer must not create, repair, repoint, or reconcile any routing resource for that DID.
- Outbound caller ID entitlement remains independent of inbound DID management mode.
- A Customer Owner cannot select a management mode, take an advanced DID back, or apply a stale simple form after takeover.
- Only Mphone staff with a narrow takeover or release permission may change management ownership.

For an advanced DID, show a concise message:

```text
This number uses an advanced call scenario. Contact Mphone to make changes.
```

The Portal must not infer ownership from names and must not overwrite an existing unmanaged Destination, Ring Group, IVR, or dialplan.

### 11.1 Management control plane and staff permissions

The Portal Superadmin interface is the authoritative user interface for taking over, publishing, cancelling, and releasing a DID. FusionPBX remains the execution environment and may be used to edit the separately created Advanced draft, but it must not expose a management-mode selector and must not change routing ownership merely because a FusionPBX administrator edits a resource.

The staff interface should be available from the Customer or Phone Number detail and show at least:

- Current management mode and management revision.
- Current active-route version and route type.
- Transition status and last synchronization result.
- Drift or fingerprint conflict status.
- Last recoverable Simple snapshot, visible only to authorized Mphone staff.
- Actions allowed in the current state, such as **Take over as Advanced**, **Open Advanced draft in FusionPBX**, **Validate and Publish**, **Cancel takeover**, and **Release to Simple**.

Use narrow staff permissions rather than treating every FusionPBX `admin` or `superadmin` as an authorized routing operator:

```text
call_routing_takeover
call_routing_publish_advanced
call_routing_cancel_transition
call_routing_release
call_routing_view_snapshot
```

All Portal, CLI, support, and emergency operations must invoke the same server-side transition service. Direct updates to management mode, management revision, transition status, or the active-route reference are unsupported. Emergency or break-glass use must require an explicit reason and produce the same audit record as the Portal workflow.

### 11.2 Mphone takeover workflow

When a Customer requests advanced routing, Mphone must use a controlled takeover rather than editing Portal-generated resources in place:

1. Revalidate the DID, Customer, Domain, current mode, revision, and generated-resource fingerprints.
2. Atomically change the DID from `portal_simple` to `transitioning_to_advanced`, increment the management revision, and reject all subsequent Portal mutations for that DID.
3. Preserve the current simple desired state, assignments, generated UUIDs, and active route as a recoverable snapshot. Simple assignments become suspended; they are not deleted.
4. Create or clone a separate Advanced draft resource graph with new UUIDs. Mphone may open that draft in FusionPBX and add time conditions, holidays, queues, external destinations, or multi-level IVRs without modifying the retained Simple graph.
5. Return to the Portal Superadmin workflow to validate the complete Advanced graph and its XML. Editing the draft in FusionPBX does not publish it.
6. Use the Portal Superadmin **Validate and Publish** action to switch the DID's single active-route reference from the last Simple version to the Advanced version as the final publication step.
7. Set the mode to `mphone_advanced` and record the actor, before/after state, revision, and resource references in the audit trail.
8. If preparation or publication fails, leave or restore the simple active route and return the management state to `portal_simple`.

Changing React visibility is not a lock. Every Portal mutation must read the current server-side mode and management revision immediately before saving. A stale request must return `409 route_management_changed` without changing desired state or FusionPBX resources.

The Portal Superadmin workflow may cancel a takeover before Advanced publication. Cancellation must discard or disable the unpublished Advanced draft, restore the state to `portal_simple`, increment the management revision, and retain the unchanged Simple active route. It must not silently cancel after Advanced publication.

### 11.3 Returning a DID to simple management

A Customer cannot perform this transition. Authorized Mphone staff may explicitly release an advanced DID by either restoring the last known-good simple snapshot or creating and validating a new simple version. The system must not attempt to infer a simple configuration from an arbitrary advanced dialplan.

The release action is initiated from Portal Superadmin and must require `call_routing_release`, explicit confirmation, and a reason. It atomically changes the state to `transitioning_to_simple`, increments the management revision, and keeps Customer Portal writes locked. The transition service then prepares and validates the Simple graph, switches the single active-route reference, and only then sets the mode to `portal_simple`. If preparation or publication fails, the Advanced route remains active and the DID returns to `mphone_advanced`. The action requires complete audit logging.

### 11.4 Transition service contract

The implementation must expose one internal transition service used by every authorized interface. Its business operations are equivalent to:

```text
takeover(did_uuid, expected_revision, reason)
publish_advanced(did_uuid, draft_version_uuid, expected_revision)
cancel_takeover(did_uuid, expected_revision, reason)
release_to_simple(did_uuid, simple_version_uuid, expected_revision, reason)
```

Each operation must acquire a per-DID database lock, validate the current state and expected revision, be idempotent for a caller-supplied operation key, and write the actor, reason, before/after state, revisions, route references, validation result, and outcome to the audit trail. The service—not a controller or FusionPBX page—owns state-machine enforcement and active-route publication.

## 12. Apply Workflow and Failure Safety

Changes should be staged in the UI and applied explicitly with **Save and Apply**.

The server workflow is:

1. Verify Owner authorization and tenant scope.
2. Re-read the DID management mode and revision; reject anything other than the expected `portal_simple` revision with HTTP `409`.
3. Validate all referenced resources, entitlements, and generated-resource fingerprints.
4. Validate the complete proposed configuration.
5. Record a new configuration version/change set.
6. Build or update an inactive route version and validate its references and XML.
7. Publish by changing the DID's single active-route reference only after the new version is complete.
8. Refresh the required XML/cache state and verify the published route.
9. Mark the version active and write an audit event.
10. On failure, retain or restore the last working active-route reference.

UI states:

- Unchanged
- Unsaved changes
- Applying
- Applied
- Apply failed

The current working call path must remain active if a new apply operation fails.

## 13. Portal Service Shape

Use narrow endpoints under `app/portal/service/`; do not introduce a generic configuration writer.

Tentative responsibilities:

```text
GET  phone configuration and authorized resources
GET  extension inbound summary and authorized outbound numbers
POST phone default answering-group configuration
POST extension outbound caller-ID configuration
POST phone greeting configuration
POST phone keypad configuration
POST greeting upload

Mphone staff transition operations, implemented through the shared transition service:

POST take over DID as Advanced
POST validate and publish Advanced draft
POST cancel unpublished takeover
POST release DID to a validated Simple version

Mphone staff DID lifecycle operations, implemented through the shared DID lifecycle service:

GET  DID inventory and assignment history
POST reserve or assign DID to Customer and Domain
POST suspend or resume DID service
POST transfer DID to another Customer or Domain
POST release DID into quarantine
```

Each Customer mutation endpoint independently performs Owner, Customer, Domain, ownership, entitlement, and payload validation. Each staff transition endpoint independently validates the staff permission, DID scope, expected state and revision, payload, and transition preconditions.

Customer configuration endpoints require the exact Customer Owner role. Staff transition endpoints instead require the corresponding narrow Mphone permission and must not accept a FusionPBX administrator role as sufficient authorization. Transition controllers must delegate state changes to the shared transition service rather than writing routing-management fields directly.

Staff DID lifecycle endpoints require the corresponding narrow inventory permission and must delegate assignment and lifecycle changes to the shared DID lifecycle service. That service must use per-DID locking, assignment revisions, idempotency keys, and the routing publication service; controllers and provider import jobs must not write active assignment ownership directly.

Every response used by an editable form includes the current per-DID management mode and revision. Every mutation submits the revision it was based on; the server rechecks both values and rejects stale or non-simple requests with HTTP `409`.

Exact endpoint filenames will be selected during implementation to match surrounding Portal conventions.

## 14. Delivery Phases

### Phase 0 — Discovery and specification freeze

Implementation record: [`PHASE_0_SIMPLE_CALL_ROUTING_DISCOVERY.md`](PHASE_0_SIMPLE_CALL_ROUTING_DISCOVERY.md). Phase 0 was completed on 2026-08-31 without changing live telephony or Customer data.

- Confirm authoritative DID, extension, caller ID, and group ownership sources.
- Inventory and normalize all known DIDs, reconcile duplicate representations, and identify provider/service status sources.
- Define DID inventory, assignment, entitlement, quarantine, transfer, and Domain-migration state machines.
- Define uniqueness constraints that prevent multiple active or activation-pending Customer assignments for one DID.
- Inventory existing Destinations, Ring Groups, recordings, IVRs, and advanced routes.
- Define managed-resource identification and conflict rules.
- Define the per-DID state machine, management revision, fingerprints, active-route pointer, and stale-request behavior.
- Define the desired-state schema and audit strategy.
- Define the shared transition-service contract, per-DID locking, idempotency behavior, and staff permission mappings.
- Define the Portal Superadmin DID-management workflow and the safe link for opening only the Advanced draft in FusionPBX.
- Define Portal Superadmin inventory, assignment, suspension, release, transfer, and assignment-history workflows.
- Define safe backup and rollback procedures for affected tables.
- Produce test fixtures for at least two Customers in the same Domain where supported.
- Produce an implementation-ready specification and migration plan. Customer routing writes must not begin while authoritative ownership, existing-resource classification, or lifecycle behavior remains unresolved.

### Phase 1 — DID and routing-publication foundation

Implementation record: [`PHASE_1_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md`](PHASE_1_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md). Phase 1 was implemented locally on 2026-08-31 with Customer routing writes explicitly disabled.

- Add the DID inventory and historical assignment records required by the discovery specification.
- Add inbound and outbound caller-ID entitlement records linked to assignment revisions.
- Add the per-DID routing-management record, management revision, transition state, configuration version, and single active-route reference.
- Add the shared DID lifecycle service with per-DID locking, revisions, idempotency, and audit events.
- Add the shared route preparation, validation, publication, verification, and rollback primitives used by both Simple and Advanced routes.
- Add managed-resource fingerprints, conflict detection, configuration history, and audit storage before publishing the first managed route.
- Add safe import and reconciliation tooling that classifies existing DIDs and routes without adopting them from number matching alone.
- Add schema migrations, backups, rollback procedures, and automated tests for assignment uniqueness, stale revisions, locking, idempotency, and failed publication.
- Do not expose Customer routing writes in this phase.

### Phase 2 — Mphone staff DID lifecycle

Implementation record: [`PHASE_2_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md`](PHASE_2_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md). Phase 2 was implemented locally on 2026-08-31; the DID inventory remains empty until staff explicitly adds a number.

- Add Portal Superadmin inventory, assignment detail, assignment history, and state-aware actions.
- Add reserve, assign, suspend, resume, release, quarantine, transfer, and Domain-migration workflows through the shared DID lifecycle service.
- Create and publish a minimal valid initial route as part of assignment; do not activate or expose the assignment until publication is verified.
- Revoke or restore outbound caller-ID entitlement as required by suspension, release, and transfer.
- Add provider-state reconciliation and actionable staff diagnostics without treating provider data as Customer authorization.
- Verify retry and recovery behavior for pending assignment, failed publication, suspension, transfer, release, and quarantine.
- Keep all DID lifecycle mutations restricted to narrow Mphone staff permissions.
- Do not expose Customer routing writes in this phase.

### Phase 3 — Basic Simple routing

Implementation record: [`PHASE_3_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md`](PHASE_3_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md). Phase 3 was implemented locally on 2026-08-31 and enables Owner-only Simple routing writes through versioned publication.

- Add Owner-only resource reads and mutations.
- Add a read-only inbound-number summary and editable outbound caller ID to the Extensions screen.
- Add the editable Default answering group to the Phone Numbers screen.
- Persist per-DID Default answering-group membership as the single source of inbound assignment.
- Automatically create/update simultaneous Ring Groups.
- Apply authorized outbound caller IDs.
- Use the Phase 1 versioned publication and rollback mechanism for every **Save and Apply** operation.
- Add server-side mode/revision checks and conflict detection before enabling the first Portal write.
- Do not include greeting or keypad behavior yet.

### Phase 4 — Greeting and keypad

Implementation record: [`PHASE_4_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md`](PHASE_4_SIMPLE_CALL_ROUTING_IMPLEMENTATION.md). Phase 4A and 4B were implemented locally on 2026-08-31 with separate recording/keypad validation and test gates.

#### Phase 4A — Greeting

- Add upload, selection, preview, and validation.
- Add per-DID greeting enable/disable.
- Implement greeting-to-default-Ring-Group routing.
- Test missing, invalid, replaced, and referenced media.

#### Phase 4B — Keypad

- Add per-DID keypad enable/disable.
- Add digit `0-9` destination mapping.
- Support authorized extension and group targets.
- Implement timeout/no-input fallback to current DID members.
- Implement invalid-input behavior.
- Restore the previous simple mode when keypad is disabled.
- Add the server-derived Call flow summary for direct, greeting-only, and keypad routes.

Phase 4A and Phase 4B may ship in one release, but they must have separate test gates because media processing and keypad routing have different failure modes.

### Phase 5 — Advanced takeover and operational hardening

- Add an Mphone-only direct takeover from `portal_simple` to `mphone_advanced`; Customer writes are locked immediately and staff edit the live FusionPBX route.
- Do not expose version history or rollback to Customers. Customers see only the current management mode and concise actionable errors.
- On release to Basic, staff select at least one Customer extension. The system builds, verifies, and cuts over to a new minimal Basic route before returning to `portal_simple`.
- Automatically delete only the DID Destination, a verified dedicated entry dialplan, and old Basic resources with exact UUID ownership.
- Never automatically delete manually managed IVRs, queues, time conditions, recordings, or ring groups. Show direct action references as cleanup suggestions for staff.
- Stop before changing the route when the active Destination is ambiguous or the entry dialplan is shared.
- Complete backend audit, transition status, actionable failures, and the Mphone operational runbook.

## 15. Required Test Matrix

### Functional routing

- One DID with one member in its Default answering group.
- One DID with multiple members in its Default answering group.
- One extension appearing read-only under multiple inbound DIDs.
- Multiple extensions sharing one outbound caller ID.
- Greeting enabled without keypad.
- Keypad enabled with a valid digit.
- No digit entered.
- An unmapped digit entered.
- The Call flow summary matches the effective generated route in every simple mode.
- A target extension or group disabled or deleted.
- No extension assigned to the DID.
- Keypad disabled and direct routing restored.
- Greeting disabled and direct routing restored.

### Authorization and isolation

- Owner can read and modify authorized configuration.
- Every non-Owner role is rejected by mutation endpoints.
- Customer A cannot submit a DID, extension, group, or recording UUID belonging to Customer B.
- A workspace change invalidates stale form assumptions.
- Browser-supplied Customer or Domain identifiers cannot expand scope.
- A stale Portal form opened before takeover is rejected with HTTP `409` and changes nothing.
- A Customer Owner cannot move an advanced DID back to simple management.
- Only an authorized Mphone staff action can take over or release a DID.
- A FusionPBX `admin` or `superadmin` without the narrow Mphone permission cannot change management ownership.
- Directly editing an Advanced draft in FusionPBX neither publishes it nor changes the management mode.
- Portal, CLI, and break-glass transition attempts enforce the same state machine, revision checks, and audit requirements.
- A Customer Owner cannot reserve, assign, transfer, suspend, release, or reclaim a DID.
- A FusionPBX administrator without the narrow DID permission cannot change a DID assignment.
- A DID assigned to Customer A cannot be exposed to or used as caller ID by Customer B, including when both share a Domain.
- Provider synchronization cannot grant Customer entitlement merely because a matching number or Destination exists.

### DID lifecycle

- Canonically equivalent number formats resolve to one DID inventory identity.
- Concurrent attempts to assign one DID to different Customers allow at most one to succeed.
- Failed provisioning or route publication does not expose a pending DID to the Customer.
- Retrying an assignment with the same idempotency key creates no duplicate assignment, Destination, or route graph.
- Suspension is reversible, blocks Customer writes, revokes outbound caller-ID use, and applies the defined inbound behavior.
- Release retains history and moves the DID into quarantine before reuse.
- A quarantined DID cannot be assigned until the cooling-off policy permits it.
- Transfer closes the source assignment and creates a target assignment without ever producing two active assignments.
- Customer transfer and Domain migration use new target routing UUIDs and do not reuse source-Customer resources.
- A failed transfer leaves or restores one unambiguous active Customer and route.

### Reliability

- A failed FusionPBX synchronization does not break the existing call route.
- Reapplying an unchanged configuration is idempotent.
- Partial generated resources are detected and reconciled.
- An advanced DID is never overwritten.
- Simple and advanced resource graphs have separate UUIDs and are never edited by both owners.
- Failed advanced preparation leaves the simple route active and writable.
- Failed advanced publication retains or restores the last active simple route.
- Cancelling an unpublished takeover leaves the prior Simple route active and increments the management revision.
- A failed release leaves the Advanced route active and returns the DID to `mphone_advanced`.
- Suspended simple assignments and their snapshot remain recoverable after takeover.
- Audit records identify the actor and before/after configuration.

## 16. MVP Acceptance Criteria

The MVP is complete when:

- Only a Customer Owner can mutate the feature through the Portal.
- The Owner sees only resources authorized for the active Customer.
- DID visibility is derived from an active assignment, not from `domain_uuid`, number matching, or FusionPBX Destination presence.
- Each DID has at most one active Customer assignment, and assignment history is retained across release or transfer.
- DID assignment, suspension, transfer, and release are Mphone-only operations performed through Portal Superadmin or another client of the shared DID lifecycle service.
- An assigned DID is exposed to the Customer only after provisioning and its initial route are validated and published.
- Released DIDs enter quarantine before they may be assigned again.
- Inbound and outbound values cannot be entered outside the authorized catalogue.
- Extensions in the same Default answering group ring simultaneously.
- Inbound DID membership is edited only on the Phone Numbers screen and is read-only on the Extensions screen.
- A greeting can operate with or without keypad mode.
- Keypad mode prevents immediate default ringing.
- No input and final invalid input route to the current Default answering group.
- The Phone Numbers screen shows a server-derived summary of the route that will be applied.
- Disabling keypad mode restores the prior simple route.
- Outbound caller ID remains independent of inbound routing mode.
- Advanced and unmanaged routes are protected from Portal writes.
- Management mode is enforced per DID on the server for every mutation.
- Takeover locks Portal writes before Mphone prepares the advanced route.
- Customer Owners cannot release an advanced DID back to simple mode.
- The Customer Phone Numbers screen hides suspended Simple controls and values while the DID is Advanced, and shows only the management message plus an optional customer-safe active-route summary.
- All takeover, publication, cancellation, and release actions are initiated through Portal Superadmin or another authorized client of the same transition service.
- Saving an Advanced draft in FusionPBX does not publish it or change routing ownership.
- Simple and advanced routes are separate versions and only one active-route reference is published.
- Every change is audited.
- The previous working route survives a failed apply operation.

## 17. Recommended Implementation Order

Complete the phases in dependency order:

```text
Discovery and specification freeze
    -> DID and routing-publication foundation
    -> Mphone staff DID lifecycle
    -> Basic Simple routing
    -> Greeting and keypad
    -> Advanced takeover and operational hardening
```

Phase 1 is a prerequisite for every managed route, including the initial route created during DID assignment. Phase 2 must prove that DID assignment, publication, suspension, transfer, release, and recovery are safe before Phase 3 enables the first Customer routing write.

Validate DID entitlement, outbound caller-ID authorization, and automatic Ring Group synchronization in Phase 3 before introducing media or keypad behavior. Phase 4A and Phase 4B may be developed in the same delivery window, but greeting and keypad behavior must be tested independently.

Only the Advanced staff workflow is deferred to Phase 5. Its management state, revision, route-versioning, active-route pointer, audit, conflict-detection, and rollback primitives belong to Phase 1 and must not be postponed. This order removes the circular dependency between DID assignment and initial-route publication while keeping every delivery independently testable.
