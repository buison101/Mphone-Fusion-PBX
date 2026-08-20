# Phase 1 Implementation Record

## Delivered

### Overview

- Reporting windows: 24 hours, 7 days, 30 days, and 90 days, with all/inbound/outbound/local direction filters
- Live call KPI remains independent from historical CDR availability
- Historical KPIs: total, answered, missed, inbound, outbound, answer rate, total talk time, and average talk time
- Hour buckets for 24 hours and day buckets for longer windows
- Previous equivalent period returned for KPI comparison work
- Seven-status distribution returned and visualized
- Recent calls remain tied to the same authorized scope and reporting window

### Calls

- Quick tabs for all, inbound, outbound, local, missed, and recorded calls
- Server-side date, direction, status, extension, maximum-wait, minimum-talk, recording, and text filters
- Server-side pagination restricted to 20, 50, or 100 rows
- Wait and talk time shown separately
- Detail drawer with start/answer/end times, durations, hangup cause, SIP disposition, UUID, and recording
- Recording player with native seeking, ±10-second controls, speed controls, volume, and authorized download
- CSV export protected by `xml_cdr_export_csv`, capped at 10,000 rows, and using the same authorized filters as the table
- Session capability response expanded for CDR, recording, and CSV presentation decisions

## Security Rules Preserved

- Every CDR query remains pinned to `domain_uuid`.
- Users without `xml_cdr_domain` remain restricted to assigned extension UUIDs.
- Selecting an extension only narrows the existing scope; it cannot widen it.
- Recording paths are never returned to the SPA.
- Recording stream lookup independently enforces domain, extension, and recording permissions.
- CSV export independently enforces `xml_cdr_export_csv`.
- Filters use allow-lists and bound numeric/text input.

## Verification

Run:

```sh
php app/portal/resources/tests/phase0_self_test.php
php app/portal/resources/tests/phase1_self_test.php
find app/portal -path '*/node_modules' -prune -o -type f -name '*.php' -print0 | xargs -0 -n1 php -l
cd app/portal/spa
npm run lint
npm run build
```

Verified locally on 2026-08-21:

- The authenticated admin endpoint returned domain-wide Dashboard and Calls data; filtered totals matched the status distribution.
- The 10002 to 10001 call returned 43 seconds of talk time and an authorized recording.
- Admin CSV export returned HTTP 200 with 426 data rows plus its header.
- A regular user was restricted to assigned extensions 10003/10004; querying extension UUID 10001 returned zero rows.
- The same regular user received HTTP 403 for CSV export.
- Phase 0 and Phase 1 self-tests, PHP syntax checks, SPA lint, and production build passed.

## Manual Verification Still Required

- Confirm recording play succeeds for an owned call and a foreign UUID is refused.
- Visually verify the 24-hour and long-range charts in light and dark modes.
- Confirm CSV opens correctly in the target spreadsheet application, including Vietnamese text.

## Deferred from Phase 1

- DID, Queue, and Ring Group selectors need a dedicated authorized options endpoint and belong with Phase 2 reporting dimensions.
- Fully custom Overview dates are deferred; Calls already supports a custom date range.
- Column visibility persistence is deferred until additional Phase 2 columns make it useful.
- Transcript presentation is deferred to the enrichment phase.
- Related-leg conversation grouping requires a separately tested grouping model and does not modify raw CDR rows.
