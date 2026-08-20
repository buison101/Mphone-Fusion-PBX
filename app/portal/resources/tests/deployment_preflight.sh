#!/bin/sh
set -eu

root=/var/www/fusionpbx
failed=0

printf '%s\n' 'Git repositories:'
for repo in "$root" "$root/app/transcribe" "$root/app/language_model"; do
	branch=$(git -c safe.directory="$repo" -C "$repo" branch --show-current)
	head=$(git -c safe.directory="$repo" -C "$repo" rev-parse --short HEAD)
	printf '  %s: %s @ %s\n' "$repo" "$branch" "$head"
done

printf '%s\n' 'Forbidden staged runtime artifacts:'
found_artifacts=0
for repo in "$root" "$root/app/transcribe" "$root/app/language_model"; do
	artifacts=$(git -c safe.directory="$repo" -C "$repo" diff --cached --name-only -- \
		'*.gguf' '*.bin' '*.dump' '*.sql.gz' '*__pycache__*' '*.pyc' || true)
	if [ -n "$artifacts" ]; then
		printf '  %s:\n%s\n' "$repo" "$artifacts"
		found_artifacts=1
		failed=1
	fi
done
if [ "$found_artifacts" -eq 0 ]; then
	printf '%s\n' '  none'
fi

printf '%s\n' 'Service state:'
for service in mphone-whisper.service mphone-summary.service transcribe_queue.service; do
	state=$(systemctl is-active "$service" 2>/dev/null || true)
	printf '  %s: %s\n' "$service" "$state"
done

if [ "$failed" -ne 0 ]; then
	printf '%s\n' 'Preflight failed.' >&2
	exit 1
fi

printf '%s\n' 'Preflight passed.'
