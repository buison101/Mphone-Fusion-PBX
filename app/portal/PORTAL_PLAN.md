# Portal Product and Implementation Plan

## 1. Purpose

This document is the implementation plan for rebuilding the FusionPBX customer portal at `/p/`.

The portal is a modern, self-service interface for using and understanding the telephone system. It is not a replacement for the FusionPBX administration interface and must not become a second PBX administration application.

Before implementing any item in this plan, read:

- `/var/www/fusionpbx/AGENTS.md`
- `/var/www/fusionpbx/app/portal/AGENTS.md`
- This file in full

Use the decoded SoftphonePro web analysis at `/var/www/fusionpbx/uiux-demo/mteam-analysis` as product and UX reference material only. Do not copy its Angular implementation or reproduce Softphone.Pro-specific account, subscription, or provisioning concepts.

## 2. Product Direction

Mphone does not currently provide, and is not expected to initially provide, the following Softphone.Pro concepts:

- Signing in with a SIP account as the product identity
- A separate Mphone personal-account system
- Independent Team, Agent, Supervisor, invitation, or subscription management
- Softphone.Pro-style cloud provisioning accounts

The first objective is a good PBX usage experience. The portal therefore uses existing FusionPBX entities as its source of truth:

- Domain
- User and assigned Extension
- DID/Destination
- Ring Group
- Call Center Queue and existing call-center agents, where configured
- CDR
- Call recording
- Voicemail
- Contact

Do not introduce a parallel Agent or Team model merely to imitate mTeam. Reports should use Extension, DID, Queue, or Ring Group until a real product requirement and data model exist.

## 3. Architectural Boundaries

The PHP administration interface remains responsible for broad or sensitive administration, including:

- Domains
- Gateways
- Dialplans
- Devices
- Creating and deleting users or extensions
- SIP credentials
- Groups and permissions
- System-wide provisioning
- Low-level FreeSWITCH configuration

The portal may expose read-heavy views and narrow, explicitly authorized writes such as call forwarding or Do Not Disturb. Each write must have a dedicated endpoint and permission check. Do not create a generic settings-write endpoint.

Every server query must be pinned to `domain_uuid`. Users without a domain-wide permission must additionally be restricted to their assigned extensions. Scope must be enforced by PHP/SQL, never by filtering data in React.

Reuse existing FusionPBX permission names wherever possible. Add a new permission only when no existing permission accurately protects the action.

Portal endpoints live under `app/portal/service/`. Do not put endpoints under a path containing `/api/` because of the existing nginx rewrite behavior.

## 4. Proposed Information Architecture

The portal has seven primary navigation items:

1. Overview
2. Calls
3. Recordings
4. Reports
5. Missed Calls
6. Contacts
7. Settings

Vietnamese labels:

1. Tổng quan
2. Cuộc gọi
3. Ghi âm
4. Báo cáo
5. Cuộc gọi nhỡ
6. Danh bạ
7. Cấu hình

All user-visible strings must be present in both English and Vietnamese locale files.

## 5. Shared Filter Model

Overview, Calls, Recordings, and Reports should use a common filter vocabulary:

- Today
- Yesterday
- Last 7 days
- Last 30 days
- Last 90 days where the endpoint permits it
- Custom date range
- One or more allowed extensions
- Direction: all, inbound, outbound, local
- Status
- DID
- Queue
- Ring Group

The selected date range and principal filters should persist while moving between analytics screens. Persist display preferences in browser storage, but never treat browser state as authorization.

All filtering, sorting, aggregation, and pagination over CDR data must be server-side.

## 6. Screen Specifications

### 6.1. Overview

The Overview screen answers: how is the telephone system being used in the selected period?

#### KPI cards

Show six to eight cards, depending on available width:

- Total calls
- Inbound calls
- Outbound calls
- Answered calls
- Missed calls
- Inbound answer rate
- Total talk time
- Average talk time

Where practical, show a comparison with the immediately preceding equivalent period. Clearly distinguish a percentage-point change from a percentage change.

#### Charts

Provide:

- Time-series chart for total, inbound, outbound, answered, and missed calls
- Status distribution for answered, missed, no answer, busy, voicemail, cancelled, and failed
- Hour-of-day volume chart
- Day-of-week by hour heatmap

The heatmap should allow the displayed metric to change between call volume, average wait time, and missed rate when those metrics are available.

#### Recent calls table

Columns:

- Start time
- Direction
- Extension
- Remote party
- Status
- Wait time
- Talk time
- Recording action
- Details action

### 6.2. Calls

Calls is the primary operational table.

#### Quick tabs

- All
- In progress
- Inbound
- Outbound
- Local
- Missed
- With recordings

#### Filters

- Date range
- Extension
- Phone number search
- DID
- Direction
- Status
- Wait-time range
- Talk-time range
- Queue
- Ring Group
- Recording availability

#### Table columns

- Start time
- Extension
- Direction
- Remote number/contact
- DID or Queue
- Status
- Wait time
- Talk time
- Total duration
- Recording
- Actions

Support server-side sorting, server-side pagination, page sizes of 20, 50, and 100, selectable columns, and CSV export of the current filtered result.

#### Call details drawer

Open details in a side drawer rather than navigating away. Include:

- Caller and destination
- Extension
- Start, answer, and end times
- Direction and normalized status
- Wait, talk, and total duration
- Hangup cause and SIP disposition
- DID, Queue, Ring Group, or IVR association
- Recording player
- Transcript and summary when available
- Related call legs when a conversation relationship can be established
- Technical identifiers in a collapsed advanced section
- Click-to-call action when permitted

Do not expose filesystem recording paths or other server internals to the browser.

### 6.3. Recordings

Recordings is a dedicated operational and storage view.

#### KPIs

- Recording count
- Total recorded duration
- Storage used, when it can be calculated efficiently
- Recordings created today
- Recordings approaching retention expiry
- Recordings with transcripts

#### Charts

- Recording count by day
- Storage growth by day
- Recorded duration by Extension
- Duration distribution: under 1 minute, 1–3 minutes, 3–10 minutes, over 10 minutes

#### Table

- Date/time
- Extension
- Remote party
- Direction
- Duration
- File size
- Format
- File availability/expiry state
- Transcript state
- Play
- Download

#### Player

The common recording player should support:

- Play and pause
- Waveform/progress display
- Seek
- Rewind and forward
- Playback speed: 0.75, 1, 1.25, 1.5, and 2
- Volume
- Current and total time
- Download when permitted
- Clear unavailable/expired state

Future recording enhancements may include tags, notes, timestamped comments, transcript search, and summaries. Video and screen recording are out of scope.

### 6.4. Reports

Do not reproduce the large mTeam report catalogue. Start with six focused reports that share filters and definitions.

#### A. Call Volume

Group by hour, day, week, or month. Include:

- Total
- Inbound
- Outbound
- Answered
- Missed
- Answer rate
- Average talk time

#### B. Extension Performance

Use the term Extension, not Agent, unless the report is explicitly based on FusionPBX Call Center agents.

Columns:

- Extension
- Total calls
- Inbound
- Answered
- Missed
- Outbound
- Total talk time
- Average talk time
- Answer rate

Charts should show top extensions by call count, talk time, and answer rate.

#### C. Inbound Quality

Include:

- Total inbound
- Answered
- Missed/abandoned
- Answer rate
- Average and maximum wait
- Calls answered within the configured SLA threshold
- Wait-time distribution
- Answered and abandoned calls by wait-time bucket

#### D. Outbound Performance

Include:

- Total outbound
- Connected calls
- Successful calls
- Success rate
- Unique numbers dialed
- Average talk time

An outbound call is successful when `billsec` reaches a configurable minimum. The default and displayed definition must be explicit.

Provide a table grouped by dialed number with call count, connection result, successful call count, total talk time, and most recent attempt.

#### E. Time Distribution

Include:

- Day-of-week by hour heatmap
- Inbound by hour
- Calls by day of week
- Peak call periods
- Periods with the highest missed rate

#### F. DID and Queue

Only render dimensions that have data.

DID table:

- DID
- Total inbound
- Answered
- Missed
- Answer rate
- Average wait
- Total talk time

Queue/Ring Group table:

- Name
- Inbound calls
- Answered
- Abandoned/missed
- Answer rate
- Average and maximum wait
- Top answering Extension where derivable

### 6.5. Missed Calls

Missed Calls is an operational workflow, not merely a saved filter.

#### KPIs

- Unprocessed
- Called back
- Successfully reached
- Overdue
- Average callback time

#### Table

- Missed-call time
- Caller number/contact
- DID or Queue
- Intended Extension
- Number of missed attempts
- Most recent callback
- Callback result
- Processing state
- Handler, only if a reliable FusionPBX user mapping exists

Initial states:

- Open
- In progress
- Called back
- Resolved
- Ignored

The first release may infer callbacks by finding a later outbound CDR to the same normalized number. Do not modify the original CDR. A later release may add an explicit domain-scoped workflow table.

#### Charts

- Missed calls by day
- Missed calls by hour
- Callback delay distribution
- Callback success rate
- DIDs or extensions with the most missed calls

### 6.6. Contacts

Focus on calling and call context, not full CRM administration.

Provide:

- Company contacts
- Contacts accessible to the current user
- Internal extension directory
- Search by name, company, or phone number
- Last interaction
- Recent call count
- Click-to-call
- Add a contact from a CDR when permitted
- Contact name resolution in call tables

Do not copy the complete FusionPBX contact administration interface into the portal.

### 6.7. Settings

Settings contains only narrow self-service PBX controls.

#### Extensions

Show assigned extensions and read-only operational information:

- Extension number
- SIP registration status
- Registered devices
- Caller ID
- Voicemail state
- Recording policy
- Do Not Disturb
- Call waiting

Never return or display SIP passwords.

#### Call Forwarding

Subject to dedicated permissions, allow:

- Forward all
- Forward on busy
- Forward on no answer
- Forward when not registered
- Destination
- Ring duration before forwarding

Each write must have validation, CSRF protection, a dedicated permission check, and a dedicated endpoint.

#### Voicemail

Potential self-service functions:

- Enable/disable voicemail when permitted
- Notification email
- Attach audio to email
- List, play, download, and delete own voicemail messages
- Change own voicemail PIN when permitted
- Manage personal greetings

#### Recording Policy

Display or, with an explicit permission, change the assigned extension policy:

- Disabled
- Inbound
- Outbound
- Local
- All

Show retention and privacy information. Playback and download remain independently permission-controlled.

#### Notifications

Preferences may cover:

- Missed calls
- New voicemail
- Recording/transcript ready
- Extension registration lost
- Recording storage warning

Start with existing email mechanisms. Add browser push only after subscription storage, revocation, and anti-spam rules are designed.

#### Report Definitions

Important domain-scoped settings:

- Inbound SLA threshold in seconds
- Minimum outbound talk time considered successful
- Reporting timezone
- First day of week
- Default report range
- Phone-number masking policy
- Recording download policy
- Recording retention display

Changing a definition that affects metrics must be visible in the report UI.

## 7. Data and Metric Rules

### Call status

Use the existing shared call-status logic in `app/portal/resources/call_status.php`. Never classify a call as answered solely because `answer_stamp` is populated.

The supported normalized statuses are:

- answered
- no_answer
- busy
- missed
- voicemail
- cancelled
- failed

Totals and status filters must use the same SQL expression so the categories partition the result set consistently.

### Durations

- `duration`: total session duration
- `billsec`: connected/talk duration
- `waitsec`: wait duration where FusionPBX provides it

Labels and tooltips must state which definition is being used.

### Scope

- Always require a valid `domain_uuid`.
- Domain-wide data requires the appropriate existing domain permission.
- Otherwise restrict CDR and live calls to extensions assigned to the current user.
- Apply equivalent scoping to recordings, contacts, voicemail, queues, and settings.
- Phone-number masking must happen in the server response.

### Related call legs

Do not rewrite or delete original CDRs. A conversation view may group records using carefully tested combinations of:

- `sip_call_id`
- `bridge_uuid`
- `originating_leg_uuid`
- `cc_member_session_uuid`
- Caller/destination and a bounded time threshold

The raw legs must remain inspectable.

## 8. Table and Chart Standards

### Tables

All large tables should provide:

- Sticky header
- Server-side pagination
- Server-side sorting and filtering
- Column visibility controls
- Page sizes of 20, 50, and 100 where appropriate
- Loading skeleton
- Empty state
- Error and retry state
- Responsive small-screen behavior
- Detail drawer rather than unnecessary route changes
- Export based on the current authorized filter

Do not fetch an entire CDR dataset into the browser.

### Charts

- Each chart should answer one clear operational question.
- Prefer line, stacked column, and heatmap charts.
- Avoid excessive pie/donut charts.
- Use consistent status colors across the portal.
- Tooltips should include absolute values and percentages where meaningful.
- Allow chart selections to filter or open the underlying table where practical.
- Provide a tabular detail route or action for aggregated charts.
- Validate chart palettes as required by `app/portal/AGENTS.md`.
- Support both light and dark themes deliberately.

## 9. Features Explicitly Out of Scope

Do not implement the following as part of this portal rebuild:

- Portal login using SIP credentials
- A separate Mphone identity/account system
- Softphone.Pro-style Teams, invitations, supervisors, or subscriptions
- Creation or deletion of FusionPBX users, extensions, devices, domains, or gateways
- Viewing or changing SIP passwords
- Generic permission or group administration
- Dialplan administration
- Softphone.Pro provisioning templates or version tracking
- Softphone.Pro billing, orders, invoices, or renewals
- Asterisk `queue_log` upload or Asterisk-specific reports
- Screen recording
- Webcam monitoring
- Video recording management
- Arbitrary custom JavaScript widgets
- Attendance, shifts, breaks, ACW, and occupancy until a reliable agent-status event history exists
- Listen, Whisper, and Barge for ordinary portal users

Listen, Whisper, and Barge may later be considered in a separately permissioned supervisor experience. They are not part of the initial portal scope.

## 10. Delivery Roadmap

Each phase must be independently usable and verified before starting the next. Do not implement all phases in one large change.

### Phase 0: Foundation and Definitions

Objectives:

- Confirm existing endpoints, permissions, WebSocket services, and CDR import health
- Document metric definitions and default thresholds
- Define shared filter request/response shapes
- Define consistent table, chart, loading, empty, and error components
- Confirm English and Vietnamese terminology
- Add targeted endpoint tests or repeatable curl/database verification scripts

Exit criteria:

- Call status totals partition a known test dataset correctly
- Domain and extension scopes are proven with authorized and unauthorized test users
- No endpoint exposes filesystem paths, credentials, or cross-domain data
- Shared UX patterns are agreed before feature screens diverge

### Phase 1: Core Calling Experience

Implement:

- Rebuilt Overview
- Enhanced Calls table and filters
- Call details drawer
- Improved recording player
- CSV export
- Shared filters and display preferences

Exit criteria:

- Overview totals equal filtered Calls totals
- Status chart totals equal the unfiltered result count
- Filters and pagination are server-side
- Recording playback supports HTTP Range and respects permissions
- A user without domain-wide permission cannot access another extension's CDR or recording
- English and Vietnamese catalogues are complete

### Phase 2: Analytics and Recordings

Implement:

- Dedicated Recordings screen
- Six initial reports
- Heatmap
- Extension performance
- DID and Queue reporting
- Report definition settings, initially read-only if write policy is not ready

Exit criteria:

- Aggregates reconcile against direct database queries for a known period
- Every report displays its metric definitions
- Empty queue/DID dimensions are hidden cleanly
- Expired or missing recordings have an explicit state
- Large date ranges remain bounded and performant

### Phase 3: Operational Workflows

Implement:

- Missed Calls workflow
- Callback inference
- Contacts and contact-name resolution
- Click-to-call
- Narrow call-forwarding controls
- Voicemail self-service where permissions permit

Exit criteria:

- Callback matching uses normalized numbers and bounded dates
- Original CDRs remain unchanged
- Every write has CSRF protection, validation, a specific permission, and an audit path
- Contact and voicemail queries remain domain/user scoped

### Phase 4: Enrichment and Mphone Integration

Consider only after earlier phases are stable:

Phase 4.0 discovery and contract proposal is recorded in `PHASE_4_0_DISCOVERY.md`. It makes no runtime or schema changes. Mphone continues to support third-party SIP login and the current Extension-via-Supabase flow remains unchanged while identity/account design is handled in the independent `MPHONE_IDENTITY_ACCOUNT_PLAN.md` workstream. That decision does not block the Portal transcript pilot.

Phase 4.1 LAN pilot implementation and its summary quality gate are recorded in `PHASE_4_1_IMPLEMENTATION.md`.

- Call tags/dispositions
- Notes and timestamped recording comments
- Transcript search and call summaries
- Browser push notifications
- Mphone device status, application version, push status, and last activity
- Narrow Mphone preferences related to PBX usage

Any Mphone implementation must inspect `/mnt/linphone-android-master`, follow its `AGENTS.md`, and coordinate the server and Android contracts. Do not assume Softphone.Pro provisioning formats apply to Mphone.

## 11. Suggested New Data Models

Do not create these tables until their phase is approved and the surrounding FusionPBX schema conventions have been reviewed.

Potential models:

- Domain-scoped report definitions/thresholds
- Missed-call workflow state and audit history
- Call tag definitions
- CDR-to-tag associations
- Recording notes/comments with `offset_seconds`
- Browser push subscriptions
- Agent-status events, only if attendance/occupancy later becomes a real requirement

Every new table must include appropriate UUIDs, `domain_uuid`, audit fields, indexes, application metadata, permissions, and upgrade/install definitions following FusionPBX conventions.

## 12. Implementation Workflow for AI Agents

For each approved feature:

1. Read the applicable repository and portal instructions.
2. Inspect current code, schema, permissions, and local changes before editing.
3. State the feature scope and the phase it belongs to.
4. Define the server-side authorization and data contract first.
5. Implement the smallest coherent endpoint change.
6. Verify domain and extension isolation, including a negative access case.
7. Implement the React view using existing Mantis components and design tokens.
8. Add both English and Vietnamese strings.
9. Rebuild the SPA after source changes.
10. Run focused PHP syntax checks, frontend lint/build, endpoint checks, and database reconciliation.
11. Report what was verified and what still requires browser/manual validation.

Do not silently expand a feature into admin functionality, a new identity system, or a Mphone change. Stop and request direction if completing the feature requires one of those scope expansions.

## 13. Completion Definition

The portal rebuild is complete when:

- The seven navigation areas are coherent and usable for PBX customers
- Calls, recordings, and report totals reconcile with FusionPBX data
- Tables and charts share consistent filters and metric definitions
- Domain and extension authorization is enforced on the server
- Important self-service PBX settings are available through narrow, audited writes
- English and Vietnamese are complete
- Light and dark layouts are supported
- No SIP credential login or parallel account/team system has been introduced
- The PHP administration interface remains the place for broad PBX administration
- The portal improves daily calling, review, reporting, callback, and voicemail workflows without duplicating FusionPBX administration
