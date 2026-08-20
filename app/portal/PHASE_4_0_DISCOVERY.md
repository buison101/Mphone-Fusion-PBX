# Phase 4.0 Discovery and Contract Proposal

Status: discovery complete; no runtime, database, Supabase, or Android changes were made.

Date: 2026-08-21

## 1. Product Boundary

Phase 4 must improve PBX usage, call review, and Mphone operational visibility. Current authentication modes are preserved while the separate identity design is undecided. Phase 4 must not introduce:

- A parallel personal account, Team, Agent, Supervisor, invitation, or subscription model
- Softphone.Pro cloud-provisioning concepts
- SIP passwords, FCM tokens, filesystem paths, or service credentials in Portal responses

Mphone continues to support direct login with third-party SIP accounts. The existing Extension-via-Supabase login path also remains available for compatibility; Phase 4 does not remove, redesign, or extend it.

FusionPBX remains the source of truth for Domain, User, Extension, CDR, recordings, permissions, and PBX configuration. Supabase is an internal delivery/session component for Mphone, not a second customer database.

## 2. Systems Inspected

### FusionPBX and Portal

- Portal plan and Phase 0–3 implementation records
- `app/transcribe`
- `app/call_recordings/resources/classes/call_recordings.php`
- `app/xml_cdr/resources/classes/xml_cdr.php`
- `app/xml_cdr/xml_cdr_details.php`
- `app/mphone_api/push_notify.php`
- `app/mphone_api/call_forward.php`
- FusionPBX tables, permissions, indexes, settings, and service state

### Mphone Android

The VirtualBox share is mounted and non-empty at `/mnt/linphone-android-master`. Its repository instructions were read before inspection.

Relevant implementation:

- `MphonePushManager`
- `PushRegistrationService`
- `FusionPbxAccountSession` and its local store
- `FusionPbxLoginService`
- call-forward services, models, screens, and push-event parsing
- Mphone/FusionPBX paths in `CorePreferences`

No Android source or resource was changed and no Android build was required for this documentation-only phase.

### Supabase

- Self-hosted deployment under `/opt/supabase/supabase-project`
- `mphone_push_devices`, `mphone_forward_calls`, and `mphone_forward_call_devices`
- Edge Functions for login, forwarding, push registration, notification delivery, and history
- Shared JWT principal validation

No environment file, service secret, JWT secret, SIP password, FCM token, or private key was copied into this document.

## 3. Current Architecture

```text
FusionPBX CDR + recording
        |
        +-- optional v_transcribe_queue --> transcribe worker --> v_xml_cdr_transcripts
        |                                                        | transcript_json
        |                                                        | transcript_summary
        |
        +-- local call-forward event --> Fusion push relay
                                         --> Supabase Edge Function
                                         --> FCM --> Mphone

Mphone --> Supabase Edge Functions --> FusionPBX database / Mphone API contracts

Portal --> FusionPBX PHP session --> domain/Extension-scoped service endpoints
```

The Portal must continue to read enrichment through FusionPBX service endpoints. It must not query Supabase directly from the browser.

## 4. Transcription Findings

### What already exists

- `v_transcribe_queue` stores domain-scoped jobs, status, processing duration, callback class/method, JSON parameters, and recording path/name.
- `v_xml_cdr_transcripts` stores one transcript JSON document and one summary per CDR with `domain_uuid` and audit columns.
- CDR ingestion can enqueue a recording when `call_recordings/transcribe_enabled` is enabled.
- The existing callback writes transcript segments to `v_xml_cdr_transcripts` and can request a language-model summary.
- Transcript JSON already carries `speaker`, `channel`, `start`, `end`, and `text`, which is sufficient for synchronized playback.
- The existing XML CDR details page renders transcript segments and safely renders the summary.
- OpenAI, Azure, Google, local, and Watson engine classes are present. The current default engine declaration is `openai`.
- The OpenAI adapter segments long audio, supports MP3/WAV handling, and recognizes Vietnamese in its language catalogue.

### Runtime state at the Phase 4.0 discovery checkpoint

- `transcribe_queue.service`: inactive
- Queue rows: 0
- Transcript rows: 0
- Summary rows: 0
- CDR rows marked with transcription: 0
- Domain-level `call_recordings`, `language_model`, or `transcribe` overrides: none
- Default transcription enable flag exists but is disabled
- API URL and API key are not enabled

Therefore Portal Phase 4 must not present transcript availability as operational yet.

This historical checkpoint was superseded for the LAN Domain by the controlled deployment recorded in `PHASE_4_1_IMPLEMENTATION.md`. Other Domains remain outside the pilot.

### Gaps and risks identified at discovery

1. The queue service builds `settings` with an undefined `$database` variable instead of `$this->database`; the worker must not be enabled before this is corrected and tested.
2. The worker marks a job `completed` after processing without a durable `failed` state, retry count, next retry, structured error, or recovery for jobs stranded in `processing`.
3. OpenAI/local adapters have unsafe failure paths and data-shape assumptions: non-string returns despite a `string` return type, undefined channel/codec/offset variables on some paths, and no reliable validation of provider responses.
4. Before this pilot, the local engine was only an HTTP client and no Whisper-compatible service was installed or running. The LAN pilot uses a new localhost-only service at `127.0.0.1:18080` because port 8000 is owned by Supabase Kong.
5. Queue filesystem fields are necessary internally but must never be returned to Portal or Mphone.
6. Transcript rows do not have an explicit processing version, engine/model, language, confidence, or retention state.
7. Summary generation depends on separate language-model settings. They are disabled, and the expected local Ollama service is not running.
8. `xml_cdr_transcript_view` is currently assigned only to `superadmin`; Portal users cannot yet view transcripts under existing permissions.
9. Automatic enqueue uses the CDR UUID as queue primary key while manual enqueue uses a new UUID. Retry and idempotency behavior must be standardized.
10. Audio may leave the installation when a remote engine is selected. This requires an explicit customer privacy decision.

The existing code is sufficient as a base for a controlled engineering pilot after hardening. It is not currently sufficient for production enablement or broad automatic transcription.

## 5. Mphone and Push Findings

### What already exists

- Self-hosted Supabase containers and Edge Functions are running.
- JWTs use issuer `mphone-fusionpbx`, audience `authenticated`, a 24-hour expiry, actor type, Fusion user/Extension UUID, and scopes.
- Push registration verifies the JWT, verifies Extension ownership against FusionPBX, and upserts by `(extension_uuid, device_id)`.
- `mphone_push_devices` stores user UUID, Extension UUID, device ID, FCM token, enabled state, locale, and timestamps.
- Live database state contains 23 enabled push-device registrations. The most recent recorded update is 2026-08-16.
- Forward-call storage contains 29 events. The most recent recorded update is 2026-08-12.
- Mphone registers its FCM token per Extension and parses started/ended forwarding notifications.
- The FusionPBX relay is localhost-only and sends to a private local Edge Function using a server-held secret.

### Missing operational metadata

The current push contract does not send or store:

- application version name/code
- Android/API version
- device model (optional and privacy-sensitive)
- last application activity
- last successful push delivery
- last push error category/time
- session expiry/health
- SIP registration health as observed by Mphone

The only current approximation for device activity is `mphone_push_devices.updated_at`, which changes on registration and is not a reliable last-seen signal.

### Authentication boundary requiring a separate plan

The current `fusionpbx-login` Edge Function accepts a numeric Extension as a login identity, validates its SIP password, creates an `actor_type=extension` session, and returns SIP provisioning data. Android retains this path. Mphone also supports direct login to third-party SIP providers; that capability must remain.

The unresolved question is how customer identity, tenant ownership, Extension assignment, authentication, recovery, and multi-Extension selection should work. It is not a Phase 4 prerequisite. Until a separate identity/account plan is approved:

1. preserve third-party SIP login;
2. preserve the current Extension-via-Supabase flow;
3. do not add a Softphone.Pro-style Team/personal-account layer;
4. do not make new Portal transcript features depend on one Mphone login mode;
5. keep JWT and API authorization compatible with explicit actor types and least-privilege scopes.

The preliminary identity workstream is documented separately in `MPHONE_IDENTITY_ACCOUNT_PLAN.md`.

## 6. Proposed Read Contracts

All proposed Portal endpoints remain under `app/portal/service/`, use the FusionPBX PHP session, require `portal_view`, validate `domain_uuid`, and apply assigned-Extension scope unless the user has the existing domain-wide CDR permission.

### Call enrichment

Proposed endpoint:

```text
GET /app/portal/service/call_enrichment.php?id={xml_cdr_uuid}
```

Proposed response:

```json
{
  "call_uuid": "uuid",
  "transcript": {
    "state": "unavailable|pending|processing|completed|failed|expired",
    "language": "vi",
    "segments": [
      { "speaker": "0", "start": 1.2, "end": 4.7, "text": "..." }
    ],
    "summary": "...",
    "engine": null,
    "model": null,
    "updated_at": "ISO-8601"
  },
  "tags": [],
  "notes": []
}
```

Rules:

- Look up the CDR by both `xml_cdr_uuid` and session `domain_uuid`.
- Reapply assigned-Extension scope independently.
- Return no recording path, queue path, raw provider response, prompt, API key, or confidence data unless explicitly approved.
- Treat transcript text as untrusted data in the SPA.
- Preserve numeric segment offsets so the player can seek without rewriting the audio.

### Mphone device status

Proposed endpoint:

```text
GET /app/portal/service/mphone_devices.php
```

FusionPBX PHP should query an internal server-to-server service or a restricted database view. The browser must not receive Supabase service credentials or query `mphone_push_devices` directly.

Proposed safe response fields:

- assigned Extension UUID and number
- opaque device display identifier, not the raw FCM token
- notification enabled state
- locale
- app version name/code, once collected
- last seen time, once explicitly collected
- last successful push and coarse last error state, once collected
- FusionPBX SIP registration state, derived server-side

Never return FCM tokens, JWTs, SIP passwords, device network addresses, or unrestricted device IDs.

## 7. Proposed Data Changes — Not Yet Applied

### FusionPBX enrichment tables

Do not overload raw CDR or transcript JSON for user-authored metadata.

Candidate tables:

1. `v_portal_call_tags`
   - tag UUID, domain UUID, name, color token, enabled/order, audit fields
2. `v_portal_call_tag_assignments`
   - assignment UUID, domain UUID, CDR UUID, tag UUID, audit fields
3. `v_portal_call_notes`
   - note UUID, domain UUID, CDR UUID, user UUID, note text, optional `offset_seconds`, audit fields

Required indexes:

- `(domain_uuid, xml_cdr_uuid)` on assignments and notes
- unique `(domain_uuid, normalized_name)` for tag definitions
- `(domain_uuid, tag_uuid, xml_cdr_uuid)` for tag filtering

Do not create a separate Team or Agent table.

### Transcription operational fields

Prefer adding structured queue fields rather than parsing error text:

- attempt count
- maximum attempts
- next attempt time
- last error code/message (sanitized)
- engine and model
- requested/detected language
- processing version

The completed transcript table may later add engine/model/language/version if reporting or migration requires them.

### Supabase device metadata

Candidate additions to `mphone_push_devices`:

- `app_version_name text`
- `app_version_code integer`
- `android_api integer`
- `last_seen_at timestamptz`
- `push_last_success_at timestamptz`
- `push_last_error_at timestamptz`
- `push_last_error_code text`

The registration function should accept bounded values, update them server-side, and continue verifying Extension ownership. Device model should be omitted unless a concrete support need justifies collecting it.

## 8. Permission Proposal

Reuse existing permissions where they fit:

- CDR and transcript lookup scope: `xml_cdr_view`, `xml_cdr_domain`
- recording access remains independently controlled by existing recording play/download permissions
- transcript read: `xml_cdr_transcript_view`, after deliberately assigning it to the intended customer group

Existing `xml_cdr_edit` and transcription queue permissions are too broad for customer-authored tags and notes. If those writes are approved, use narrow new permissions:

- `portal_call_tag_view`
- `portal_call_tag_edit`
- `portal_call_note_view`
- `portal_call_note_add`
- `portal_call_note_edit`
- `portal_call_note_delete`

Every write requires CSRF, CDR/domain/Extension re-authorization, bounded input, and audit fields. Editing another user's note should require a separately approved rule.

## 9. Notification Strategy

Recommended order:

1. Existing FusionPBX email paths for voicemail and operational warnings
2. Existing Mphone FCM path for Mphone-specific call-forward events
3. Add transcript-ready notification only after the transcript worker has reliable completed/failed states and idempotent event delivery
4. Add browser push only after Portal subscription storage, revocation, expiry, deduplication, and rate limits are designed

Do not use `v_notifications` as a customer event inbox; its current schema is a generic project-notification record and has no Domain/User/Extension scope.

## 10. Recommended Phase 4 Sequence

### Independent workstream — Mphone identity and account model

- Preserve third-party SIP login and current Extension-via-Supabase behavior.
- Decide the relationship between customer account, Fusion user, Extension, device, and SIP account.
- Define authentication, recovery, provisioning, revocation, and multi-Extension selection.
- Run this workstream independently; it does not block the Portal transcript pilot.

### Phase 4.1 — Transcript read-only pilot

- Fix and test the queue service and engine failure paths before enabling it.
- Choose local versus approved remote engine and privacy policy.
- Configure one non-production Domain.
- Enable and monitor `transcribe_queue.service`.
- Add explicit failed/retry behavior before broad automatic enqueue.
- Process a small set of recordings and reconcile segment offsets with playback.
- Implement only the scoped read endpoint and Portal transcript/summary UI.

Go/no-go evidence:

- Vietnamese transcript quality accepted on representative calls
- no recording path or provider response leak
- queue restart and failure recovery tested
- cost and processing time measured
- permission assignment approved

### Phase 4.2 — Tags and timestamped notes

- Review and create the three domain-scoped metadata tables
- Add narrow permissions and CSRF-protected endpoints
- Add tag/note filtering and audit presentation

### Phase 4.3 — Notification hardening

- Add transcript-ready/failed events with idempotency keys
- Add push delivery status without exposing tokens
- Add Portal browser push only if still required

### Phase 4.4 — Mphone operational status

- Extend registration contract with bounded version/last-seen fields
- Add internal server-side device-status view
- Render read-only Mphone status in Portal
- Add only narrow PBX-use preferences after the read contract is stable

## 11. Decisions Required Before Implementation

1. Must transcription remain on-premise, or may recordings be sent to an approved external engine?
2. Which Domains/users may view transcripts and summaries?
3. Should transcript generation be automatic for every recording, policy-based, or manual?
4. What recording/transcript retention and deletion policy applies?
5. Are summaries required in the pilot, or should the first release be transcript-only?
6. Should Mphone device status expose only version/last seen, or also coarse push health?
7. Which Mphone identity/account model should be adopted in its independent workstream?

## 12. Phase 4.0 Exit Result

Phase 4.0 is complete as a discovery/design checkpoint:

- existing transcription, summary, push, Supabase, and Mphone paths were identified;
- live readiness and data counts were verified without exposing secrets;
- authorization boundaries and proposed contracts were documented;
- required future schema changes were proposed but not applied;
- Mphone authentication modes were explicitly preserved and the unresolved identity model was separated into a non-blocking workstream;
- the transcript/summary codebase was classified as pilot-capable only after hardening, not production-ready in its current runtime state;
- no runtime service, database, Supabase, Portal SPA, or Android source was changed.
