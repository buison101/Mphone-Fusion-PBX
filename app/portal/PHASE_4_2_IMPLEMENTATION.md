# Phase 4.2 — Call Tags and Timestamped Notes

Status: implemented on 2026-08-21.

## Delivered

- Domain-scoped tag definitions with normalized unique names and bounded Mantis color tokens.
- Many-to-many call/tag assignments with indexes for call lookup and server-side filtering.
- Domain-scoped call notes with author, created/updated audit fields, and an optional recording offset.
- Call detail drawer supports creating and assigning tags, removing assignments, and adding, editing, deleting, seeking from, and reviewing notes.
- Call table shows up to three assigned tags and provides server-side filters for tag, note, transcript, and summary presence.
- Each call-table row includes an inline tag selector. Selecting a tag assigns it immediately without a confirmation dialog; an assigned tag can be removed directly from its chip.
- Admin and superadmin can disable an active tag directly below the create-tag controls. Disabled tags are removed from future selectors while existing assignments remain visible for historical accuracy.
- Tag and note content is rendered as untrusted text by React; no user-authored HTML is accepted.

## Authorization

All metadata endpoints require the FusionPBX session, `portal_view`, `xml_cdr_view`, the narrow metadata permission, and a valid Portal CSRF token for writes. Every call lookup is independently pinned to session `domain_uuid` and assigned Extensions unless `xml_cdr_domain` is present.

Permissions:

- `portal_call_tag_view`
- `portal_call_tag_assign` — assigned to user, admin, and superadmin for attaching/removing existing tags
- `portal_call_tag_edit` — assigned only to superadmin for creating and disabling the Domain-wide tag catalogue
- `portal_call_note_view`
- `portal_call_note_add`
- `portal_call_note_edit`
- `portal_call_note_delete`

Editing and deleting a note is limited to its original author. A missing, foreign-Domain, foreign-Extension, or foreign-author object returns the same not-found response.

Tags are shared inside one Domain. Only superadmin can create or disable the shared catalogue. Admin and user can only assign or remove existing tags on CDRs inside their authorized scope. Portal admin manages subordinate users but does not own Domain-wide shared configuration.

Permission changes require users to sign out and back in before the Portal session exposes the new capabilities.

## Bounds and Audit

- Tag name: 1–80 characters after whitespace normalization.
- Tag colors: `primary`, `secondary`, `success`, `warning`, `error`, or `info`.
- Note text: 1–2,000 characters.
- Timestamp: zero through the call duration, with an absolute database maximum of 86,400 seconds.
- Enrichment response: at most 100 active tag definitions and 500 notes per call.
- All writes store the acting user and timestamps; edits store update user/time.

## Verification

```sh
php app/portal/resources/tests/phase42_self_test.php
php -l app/portal/service/call_tags.php
php -l app/portal/service/call_notes.php
cd app/portal/spa && npm run lint && npm run build
```

Manual browser verification remains required for the visual layout and two authenticated roles. Test a Domain-wide user and an Extension-scoped user, including attempts to access another Domain, another Extension, and another user's note.
