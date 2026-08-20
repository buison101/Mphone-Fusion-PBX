# Phase 0: Portal Foundation

## Status

Implemented on 2026-08-21. This phase defines and verifies the foundation; it does not add the Phase 1 screens.

## Current System Inventory

### Runtime services

The portal depends on these local services:

| Service | Purpose |
|---|---|
| `nginx` | Serves `/p/` and PHP endpoints |
| `php8.2-fpm` | Runs portal service endpoints |
| `postgresql` | Stores FusionPBX configuration and CDR data |
| `freeswitch` | PBX and live call source |
| `fusionpbx-websockets` | Authenticated WebSocket router |
| `fusionpbx-active-calls` | Publishes live call state |
| `xml_cdr` | Imports completed calls into `v_xml_cdr` |

Run `resources/tests/phase0_self_test.php` to verify the services and data invariants that can be checked locally.

### Existing portal endpoints

| Endpoint | Method | Purpose | Main permission |
|---|---|---|---|
| `service/session.php` | GET | Identity, capabilities, extension scope, WebSocket token | `portal_view` |
| `service/dashboard.php` | GET | Bounded historical totals, hourly series, recent calls | `xml_cdr_view` |
| `service/calls.php` | GET | Filtered and paginated call history | `xml_cdr_view` |
| `service/recording.php` | GET | Domain/extension-scoped recording stream | recording permissions |

All four endpoints return `401` without a valid FusionPBX session. `dashboard.php` intentionally degrades to an unavailable history response when the signed-in user lacks `xml_cdr_view`; live calls may still work.

### Permission contract

`session.php` exposes only capabilities on which the SPA may branch:

- `call_active_view`
- `call_active_all`
- `call_active_domain`
- `call_active_hangup`
- `call_active_eavesdrop`
- `call_active_application`
- `call_active_codec`
- `call_active_secure`
- `call_active_profile`
- `xml_cdr_view`
- `xml_cdr_domain`
- `xml_cdr_recording`
- `xml_cdr_recording_play`
- `xml_cdr_recording_download`

The capability response controls presentation only. Each endpoint must independently enforce its permissions and scope.

## Metric Definitions

These definitions are normative for Portal screens and APIs.

| Metric | Definition |
|---|---|
| Total calls | Count of CDR rows in the authorized scope and selected filter |
| Inbound | `direction = 'inbound'` |
| Outbound | `direction = 'outbound'` |
| Local | `direction = 'local'` |
| Answered | Effective status produced by `portal_call_status_sql()` equals `answered` |
| Missed | Effective status equals `missed` |
| Unconnected | Effective status is `cancelled`, `no_answer`, `busy`, or `failed` |
| Talk time | `billsec` |
| Total duration | `duration` |
| Wait time | `waitsec` when populated; otherwise do not invent a value |
| Answer rate | Answered inbound divided by total inbound, expressed as a percentage |
| Successful outbound | Outbound call with `billsec` at or above the configured threshold |
| SLA answered | Answered inbound call with wait time at or below the configured SLA threshold |

`answer_stamp` is not proof that a call was answered. The effective status expression in `resources/call_status.php` is the single source of truth.

Rates with a zero denominator return `null`, not zero. The UI should display an em dash and explain that there was no eligible traffic.

Comparisons use the immediately preceding period of equal duration. Percentage-point and relative-percent changes must be labelled differently.

## Shared Filter Contract

### Query names

| Name | Type | Rules |
|---|---|---|
| `from` | `YYYY-MM-DD` | Inclusive start of day in the reporting timezone |
| `to` | `YYYY-MM-DD` | Inclusive end of day in the reporting timezone |
| `range` | enum | `today`, `yesterday`, `7d`, `30d`, `90d`, `custom` |
| `direction` | enum | empty, `inbound`, `outbound`, `local` |
| `status` | enum | empty or one of the seven normalized statuses |
| `q` | string | Trimmed number/name search; server applies a bounded length |
| `extension_uuid` | UUID/repeated UUID | Must belong to the authorized domain and user scope |
| `did` | string | Exact normalized DID once implemented |
| `queue_uuid` | UUID | Must belong to the authorized domain |
| `ring_group_uuid` | UUID | Must belong to the authorized domain |
| `recording` | enum | empty, `yes`, `no` |
| `page` | integer | One-based and at least 1 |
| `page_size` | enum | 20, 50, or 100 for new tables |
| `sort` | enum | Endpoint allow-list only |
| `order` | enum | `asc` or `desc` |

Current endpoints support only their existing documented subset. Phase 1 extends them incrementally; it must not accept arbitrary column or SQL names.

### Standard list response

New paginated endpoints should return:

```json
{
  "available": true,
  "scope": "extensions",
  "filters": {},
  "page": 1,
  "page_size": 20,
  "total": 0,
  "pages": 0,
  "rows": [],
  "capabilities": {}
}
```

### Standard error response

```json
{
  "error": "machine_readable_code"
}
```

Use HTTP `400`, `401`, `403`, `404`, `405`, `409`, or `500` as appropriate. Do not return an HTTP 200 response containing an error for new endpoints.

## Data Scope Contract

1. Validate `$_SESSION['domain_uuid']` before querying.
2. Add `domain_uuid = :domain_uuid` to every data lookup.
3. Without the corresponding domain permission, restrict calls to extension UUIDs assigned in the session.
4. An authorized user with no assigned extension receives an empty result, never domain-wide data.
5. Apply the same principle to recordings, contacts, voicemail, queues, and future writes.
6. Mask phone numbers on the server when a masking policy is introduced.
7. Never return recording paths, database credentials, SIP secrets, or unrestricted technical payloads.

## Shared UI States

Use `components/states/ContentState.jsx` for consistent page/card states:

- `loading`: progress indicator plus optional text
- `empty`: neutral message and optional action
- `error`: error message, optional detail, and retry action
- `forbidden`: permission message without leaking the missing resource

Tables should keep their header visible while loading or empty when that helps preserve context. Full-page session failures continue to use `SessionGate`.

## Terminology

| English | Vietnamese | Notes |
|---|---|---|
| Extension | Máy nhánh | Do not call every extension an Agent |
| Inbound | Gọi vào | |
| Outbound | Gọi ra | |
| Local | Nội bộ | |
| Talk time | Thời gian đàm thoại | Uses `billsec` |
| Total duration | Tổng thời lượng | Uses `duration` |
| Wait time | Thời gian chờ | Uses `waitsec` when available |
| Answer rate | Tỷ lệ trả lời | |
| Recording | Bản ghi âm | |
| Missed call | Cuộc gọi nhỡ | |
| DID | Số DID | Keep the standard acronym |
| Queue | Hàng đợi | |
| Ring Group | Nhóm đổ chuông | |

Mphone, SIP account login, Team, Agent, and Supervisor are not new Portal identity concepts in this phase.

## Phase 0 Exit Criteria

- [x] Runtime dependencies inventoried
- [x] Existing endpoint and permission contract documented
- [x] CDR metric definitions documented
- [x] Shared filter names and response conventions documented
- [x] Domain and extension scope rules documented
- [x] Shared UI state component added
- [x] Shared frontend call filter/status constants added
- [x] Session capabilities include CDR and recording permissions
- [x] Repeatable local self-test added
- [ ] Authenticated positive and negative browser-session tests run with representative `user` and `admin` accounts

The final item requires real authenticated test sessions for two roles. It remains a required manual verification before Phase 1 is considered production-ready; the automated self-test verifies the static scope guards and unauthenticated refusal path.
