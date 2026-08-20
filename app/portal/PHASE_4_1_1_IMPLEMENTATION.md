# Phase 4.1.1 — AI Operations Hardening

Status: implemented for the LAN pilot Domain on 2026-08-21.

## Delivered

- Independent summary states: `disabled`, `processing`, `completed`, `failed`, and `skipped`.
- Summary model, duration, attempt count, and sanitized internal error metadata.
- Existing transcript rows were backfilled without changing transcript or summary content.
- Portal displays pending, failed, disabled, and short-transcript summary states separately from transcript state.
- Authorized operators with `transcribe_queue_edit` can regenerate a summary from the existing transcript without retranscribing audio.
- Retry is a Domain/Extension-scoped POST endpoint protected by the Portal CSRF token.
- Provider errors remain in server-side operational metadata and logs; they are never returned by the Portal endpoint.
- A failed summary never deletes or invalidates the transcript.
- A `processing` state older than 15 minutes is presented as failed and can be retried, preventing permanently stuck UI state after an interrupted PHP request.

## Retention Policy

For the pilot, transcripts and summaries follow the lifecycle of their CDR. No independent automatic purge is enabled yet because the current transcript table has no database foreign key to the CDR table. Before enabling destructive retention automation, implement and dry-run an orphan report, obtain an approved retention period, and verify that CDR deletion removes the corresponding transcript metadata.

Audio, transcript text, summary text, model responses, filesystem paths, and internal error messages must not be written to routine operational reports. Aggregate monitoring may use only state, duration, attempt count, model name, Domain, and timestamps.

## Operational Monitoring

Use aggregate queries rather than reading call content:

```sql
select summary_status,
       count(*) as calls,
       round(avg(summary_duration), 1) as average_seconds,
       max(summary_attempt_count) as maximum_attempts
from v_xml_cdr_transcripts
where domain_uuid = '<domain_uuid>'
group by summary_status
order by summary_status;
```

Go/no-go review should use at least 10–20 audible Vietnamese calls and record transcript acceptance, summary acceptance, processing duration, retry rate, peak memory, and queue recovery. Other Domains remain disabled until this evidence is accepted.

## Verification

```sh
php app/portal/resources/tests/phase411_self_test.php
php -l app/portal/service/summary_retry.php
cd app/portal/spa && npm run lint && npm run build
```

Manual verification still requires two authenticated sessions: an ordinary Portal user must not see the retry action, while an operator with `transcribe_queue_edit` must be able to regenerate only summaries within their authorized CDR scope.
