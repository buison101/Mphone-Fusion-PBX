# Phase 4 — Greeting and Keypad Implementation

Status: implemented locally on 2026-08-31.

## Phase 4A — Greeting

- Owner-only WAV/MP3/OGG upload, actual MIME inspection, 10 MB limit, five-minute duration limit, and FFmpeg normalization to mono 8 kHz PCM WAV.
- Server-generated filenames, Customer/Domain recording ownership, selection, and authenticated preview.
- Per-DID greeting enable/disable. Greeting routes play the validated recording before the current simultaneous Default answering group.
- Disabling greeting publishes a new direct route version.

## Phase 4B — Keypad

- Per-DID keypad toggle and one-level digit `0-9` mapping. Each digit accepts one or more active Extensions owned by the Customer.
- A valid Customer-owned greeting and non-empty Default answering group are mandatory.
- The generated route collects one digit; mapped digits call their selected Extension group simultaneously, while timeout/no-input and invalid input fall back to the Default answering Ring Group.
- Portal does not expose FusionPBX Ring Groups. For every mapped digit, the publisher creates a versioned technical Ring Group and owns its full lifecycle with the route version.
- Greeting-only mode plays the recording once. Keypad mode allows two attempts and derives its accepted digit pattern from the configured mappings, then falls back after the final invalid/no-input attempt.
- Disabling keypad publishes greeting-only or direct mode based on the greeting toggle.
- The page displays a server-modelled customer-safe call-flow summary.

Every Save and Apply continues to use Phase 1 versioning, disabled preparation, validation, verified cutover, rollback, exact resource ownership, and mode/revision conflict checks. Greeting and keypad SQL and publisher tests are separate.

## FusionPBX publication consistency

- The managed `v_destinations` summary, `v_dialplans.dialplan_xml`, and `v_dialplan_details` now describe the same route type. Keypad details include `play_and_get_digits`, dispatch to the generated per-digit technical Ring Group, and the Default Ring Group fallback.
- Recording paths retain the FreeSWITCH `${recordings_dir}` channel variable. Path components are escaped separately so FusionPBX sanitization cannot remove the variable expression.
- Keypad-only transfer targets are not implicitly added to the Default Ring Group. Only `extension_uuids` selected for the Default answering group become Ring Group members.
- Publication verification now rejects missing greeting/keypad details, corrupt recording paths, missing keypad transfers, and a Destination action that does not match the route type.
- The publisher integration test also rebuilds XML from `v_dialplan_details` and verifies the generated action/condition graph, in addition to validating stored XML and Destination metadata.

Existing published versions remain immutable. A route published before these corrections must be saved and applied once more by its Workspace Owner to create a corrected active version; it is not mutated in place.

## Technical resource lifecycle

- Supabase route versions, desired state, operations, and audit history remain the source of truth and are retained.
- After a new route is enabled, verified, and atomically published, the superseded version's disabled FusionPBX Destination, Dialplan, Dialplan Details, Ring Groups, and Ring Group Destinations are deleted immediately.
- The historical resource ownership rows are retained and changed from `disabled` to `missing`, accurately recording that the generated FusionPBX objects no longer exist.
- If preparation or validation fails before publication, the previous route is restored and the failed version's generated FusionPBX objects are deleted immediately.
- Cleanup after a successful publication is best-effort: a cleanup error is logged and never rolls back or disables the already verified active route.
