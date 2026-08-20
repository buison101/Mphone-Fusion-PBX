# Phase 4.1 — LAN Local Transcript Pilot

Status: local Whisper, automatic transcription, and local Vietnamese call summaries are deployed for the LAN Domain.

Date: 2026-08-21

## Scope

- Pilot Domain: `192.168.1.201` (`7cac95f8-25b5-4e0f-9098-035cb7408de9`)
- Engine: local `faster-whisper`
- Model: multilingual `small`, CPU `int8`, four CPU threads, one worker
- Model path: `/var/lib/mphone-whisper/models/faster-whisper-small`
- API: `http://127.0.0.1:18080/transcribe`
- No call audio is sent to an external transcription or summary provider.
- Other FusionPBX Domains remain unchanged.

Port 18080 is deliberate. Port 8000 is already published by Supabase Kong and must not be used by Whisper.

## Runtime

- `mphone-whisper.service`: enabled and running
- `transcribe_queue.service`: enabled and running
- Python environment: `/opt/mphone-whisper/venv`
- Model cache: `/var/lib/mphone-whisper/cache`
- Whisper binds only to `127.0.0.1`
- Queue concurrency for the LAN Domain: 1
- Automatic enqueue for new LAN recordings: enabled
- Summary generation: enabled for the LAN Domain

Health check:

```sh
curl -sS http://127.0.0.1:18080/health
systemctl is-active mphone-whisper.service transcribe_queue.service
```

## Pipeline Hardening Applied

- Fixed queue-service settings initialization.
- Added attempts, maximum attempts, next-attempt time, and sanitized last-error fields.
- Added exponential retry and a terminal `failed` state.
- Added a PID lock, missing/unreadable recording checks, response validation, and an allowlisted callback.
- Added recovery for jobs stranded in `processing` for more than two hours.
- A job is completed only after its callback has persisted a transcript row.
- Local HTTP errors and invalid/empty speech responses now fail the job instead of being marked completed.
- Queue concurrency is capped at one to protect FreeSWITCH on this 4-vCPU/8-GB development machine.

A controlled missing-file test reached `failed` on attempt 3 as designed and was removed afterward.

## Verification Result

- The service health response reports `small`, `cpu`, and `int8`.
- A bundled FreeSWITCH 8-kHz spoken prompt produced one non-empty timed segment in about four seconds, proving the local decoder/model/API path works.
- PHP syntax checks, SPA ESLint, SPA production build, systemd unit verification, and diff whitespace checks pass.
- The Portal enrichment endpoint rejects an unauthenticated request with HTTP 401.

The existing 43-second LAN call cannot be used as a speech-quality sample. Its MP3 is stereo and about 50 seconds long, but both channels measure approximately `mean -91 dB` and `max -72.2 dB`, effectively silence. Whisper correctly returns no speech segments for it.

## Portal Result

- Added a Domain/Extension-scoped, read-only call-enrichment endpoint.
- The endpoint requires the existing `portal_view`, `xml_cdr_view`, and `xml_cdr_transcript_view` permissions.
- User and admin groups were granted transcript view permission; existing sessions must sign out and back in.
- The call detail drawer shows unavailable, pending, processing, failed, or completed state.
- Completed transcripts render timed speaker segments and an optional summary.
- Selecting a transcript segment seeks and plays the recording at its start time.
- Filesystem paths, queue errors, provider responses, credentials, and recording filenames are not returned.

## Local Summary Runtime

The selected summary model is Qwen3 4B Q4_K_M. It provides substantially better Vietnamese language handling than a very small classifier-style model while remaining practical for this 4-vCPU/8-GB pilot VM.

- Runtime: official `llama.cpp` CPU server, release `b10520`
- Model: `Qwen/Qwen3-4B-GGUF`, file `Qwen3-4B-Q4_K_M.gguf`
- Model path: `/var/lib/mphone-llama/models/Qwen3-4B-Q4_K_M.gguf`
- API: `http://127.0.0.1:18081/v1/chat/completions`
- Service: `mphone-summary.service`
- Context: 4096 tokens, four CPU threads, one request slot
- Idle policy: unload model memory after 60 seconds without a request
- Network exposure: loopback only
- Transcript minimum: 40 characters

The callback strips presentation markup before sending text to the model. A short transcript is left without a summary, and an unavailable or failed language model never invalidates or deletes a successful transcript.

The deployment passed all of these checks:

1. verify the model checksum/size and local health endpoint;
2. test a Vietnamese summary for content, result, action, and sentiment fields;
3. measure generation time and peak memory while Whisper is resident;
4. enable `language_model/enabled` and `call_recordings/summary_enabled` only for the LAN Domain;
5. reprocess one existing audible LAN transcript and verify Portal rendering.

The official GGUF copied from the VirtualBox share was compared byte-for-byte with its VM copy before activation. The model loaded in about three seconds. A Vietnamese synthetic call produced all four required fields in about 17.7 seconds; the response contained 186 characters. One existing audible LAN transcript was then summarized and persisted successfully with all four required fields in about 27.5 seconds. The server entered its sleeping state 60 seconds after the last request. During active generation it used approximately 3.0 GB resident memory; in the sleeping state the service cgroup retained approximately 1.2 GB and stopped consuming CPU.

## Operational Checks

```sh
journalctl -u mphone-whisper.service -n 100 --no-pager
journalctl -u transcribe_queue.service -n 100 --no-pager
curl -sS http://127.0.0.1:18081/health
journalctl -u mphone-summary.service -n 100 --no-pager
systemctl restart mphone-whisper.service transcribe_queue.service
```

Queue status must be inspected without exposing `transcribe_audio_path`, `transcribe_audio_name`, or raw transcript content in routine logs.
