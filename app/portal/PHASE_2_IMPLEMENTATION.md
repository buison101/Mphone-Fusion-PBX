# Phase 2 Implementation Record

## Delivered

### Recordings

- Dedicated recordings route and navigation item
- Bounded date and text filters with server-side pagination
- Recording count, recorded duration, created-today, and transcript KPIs
- Daily volume, duration by Extension, and duration-distribution charts
- Availability check based on the resolved file path; missing files have an explicit state
- File format and actual size for the current page without exposing filesystem paths
- Shared authorized player and download flow from Phase 1

Storage growth and retention-expiry counts are intentionally omitted because FusionPBX currently has no reliable indexed file-size or per-recording expiry metadata. Scanning every recording file for a long report would violate the bounded-performance requirement.

### Reports

Six report tabs share a bounded date range and the same server-side scope:

1. Call volume by hour/day/week/month contract
2. Extension performance
3. Inbound quality and wait/SLA distribution
4. Outbound performance and dialed-number table
5. Day-of-week/hour heatmap
6. DID, Queue, and Ring Group dimensions

Metric definitions are displayed in English and Vietnamese. SLA defaults to 20 seconds and outbound success defaults to at least 30 billed seconds. Both inputs are bounded on the server and remain read-only definitions in this phase.

Empty DID, Queue, and Ring Group dimensions are hidden with an explicit empty state. No parallel Agent or Team model was introduced.

## Authorization and Performance

- Every query is pinned to `domain_uuid`.
- Without `xml_cdr_domain`, reports and recordings are restricted to assigned Extension UUIDs.
- A selected Extension can only narrow that server scope.
- Date ranges are capped at 366 days.
- Report names, grouping periods, directions, numeric thresholds, page sizes, and search length use allow-lists or bounds.
- File existence checks only run for the current recordings page (maximum 100 rows).

## Verification

```sh
php app/portal/resources/tests/phase0_self_test.php
php app/portal/resources/tests/phase1_self_test.php
php app/portal/resources/tests/phase2_self_test.php
find app/portal -path '*/node_modules' -prune -o -type f -name '*.php' -print0 | xargs -0 -n1 php -l
cd app/portal/spa
npm run lint
npm run build
```

Manual browser verification remains required for responsive layout, both color schemes, chart tooltips, and audio controls.

The generated routes `/p/reports` and `/p/recordings` were verified through the TLS `fusionpbx` virtual host and returned HTTP 200.
