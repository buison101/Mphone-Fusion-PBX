import { useEffect, useState } from 'react';
import PropTypes from 'prop-types';

// material-ui
import Chip from '@mui/material/Chip';
import CircularProgress from '@mui/material/CircularProgress';
import Divider from '@mui/material/Divider';
import Drawer from '@mui/material/Drawer';
import IconButton from '@mui/material/IconButton';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import MenuItem from '@mui/material/MenuItem';
import TextField from '@mui/material/TextField';

// third-party
import { FormattedMessage, useIntl } from 'react-intl';

// project imports
import RecordingPlayer from 'components/recordings/RecordingPlayer';
import { CALL_ENRICHMENT_URL, SUMMARY_RETRY_URL, CALL_TAGS_URL, CALL_NOTES_URL } from 'config';
import { STATUS_COLOR } from 'utils/callStatus';

// assets
import CloseOutlined from '@ant-design/icons/CloseOutlined';

function formatSeconds(seconds) {
  const total = Math.max(Number(seconds) || 0, 0);
  return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, '0')}`;
}

function Detail({ label, value }) {
  return (
    <Stack direction="row" sx={{ justifyContent: 'space-between', gap: 2 }}>
      <Typography variant="body2" sx={{ color: 'text.secondary' }}>
        {label}
      </Typography>
      <Typography variant="body2" sx={{ textAlign: 'right', wordBreak: 'break-word' }}>
        {value || '—'}
      </Typography>
    </Stack>
  );
}

Detail.propTypes = { label: PropTypes.node, value: PropTypes.node };

export default function CallDetailsDrawer({ call, onClose, allowDownload, allowSummaryRetry, csrf }) {
  const intl = useIntl();
  const [enrichment, setEnrichment] = useState(null);
  const [loadingEnrichment, setLoadingEnrichment] = useState(false);
  const [seekRequest, setSeekRequest] = useState(null);
  const [retryingSummary, setRetryingSummary] = useState(false);
  const [summaryRetryError, setSummaryRetryError] = useState(false);
  const [metadata, setMetadata] = useState({ tags: [], available_tags: [], notes: [], capabilities: {} });
  const [selectedTag, setSelectedTag] = useState('');
  const [newTagName, setNewTagName] = useState('');
  const [tagToDisable, setTagToDisable] = useState('');
  const [noteText, setNoteText] = useState('');
  const [noteOffset, setNoteOffset] = useState('');
  const [editingNote, setEditingNote] = useState(null);
  const [metadataBusy, setMetadataBusy] = useState(false);
  const [metadataError, setMetadataError] = useState(false);

  useEffect(() => {
    const controller = new AbortController();
    setEnrichment(null);
    setMetadata({ tags: [], available_tags: [], notes: [], capabilities: {} });
    if (!call?.uuid) return () => controller.abort();
    setLoadingEnrichment(true);
    fetch(`${CALL_ENRICHMENT_URL}?id=${encodeURIComponent(call.uuid)}`, { credentials: 'same-origin', signal: controller.signal })
      .then((response) => (response.ok ? response.json() : null))
      .then((payload) => {
        setEnrichment(payload?.transcript || null);
        setMetadata({
          tags: payload?.tags || [],
          available_tags: payload?.available_tags || [],
          notes: payload?.notes || [],
          capabilities: payload?.capabilities || {}
        });
      })
      .catch((error) => {
        if (error.name !== 'AbortError') setEnrichment(null);
      })
      .finally(() => setLoadingEnrichment(false));
    return () => controller.abort();
  }, [call?.uuid]);

  const refreshMetadata = async () => {
    const response = await fetch(`${CALL_ENRICHMENT_URL}?id=${encodeURIComponent(call.uuid)}`, { credentials: 'same-origin' });
    if (!response.ok) throw new Error('metadata_refresh_failed');
    const payload = await response.json();
    setEnrichment(payload?.transcript || null);
    setMetadata({
      tags: payload?.tags || [],
      available_tags: payload?.available_tags || [],
      notes: payload?.notes || [],
      capabilities: payload?.capabilities || {}
    });
  };

  const metadataRequest = async (url, method, body) => {
    setMetadataBusy(true);
    setMetadataError(false);
    try {
      const response = await fetch(url, {
        method,
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf },
        body: JSON.stringify(body)
      });
      if (!response.ok) throw new Error('metadata_write_failed');
      await refreshMetadata();
      return true;
    } catch {
      setMetadataError(true);
      return false;
    } finally {
      setMetadataBusy(false);
    }
  };

  const assignTag = async () => {
    if (!selectedTag) return;
    if (await metadataRequest(CALL_TAGS_URL, 'POST', { action: 'assign', call_uuid: call.uuid, tag_uuid: selectedTag })) setSelectedTag('');
  };

  const createAndAssignTag = async () => {
    const name = newTagName.trim();
    if (!name) return;
    setMetadataBusy(true);
    setMetadataError(false);
    try {
      const created = await fetch(CALL_TAGS_URL, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf },
        body: JSON.stringify({ action: 'create', name, color: 'primary' })
      });
      if (!created.ok) throw new Error('tag_create_failed');
      const payload = await created.json();
      const assigned = await fetch(CALL_TAGS_URL, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf },
        body: JSON.stringify({ action: 'assign', call_uuid: call.uuid, tag_uuid: payload.tag.uuid })
      });
      if (!assigned.ok) throw new Error('tag_assign_failed');
      setNewTagName('');
      await refreshMetadata();
    } catch {
      setMetadataError(true);
    } finally {
      setMetadataBusy(false);
    }
  };

  const disableTag = async () => {
    if (!tagToDisable) return;
    const disabled = await metadataRequest(CALL_TAGS_URL, 'POST', { action: 'disable', tag_uuid: tagToDisable });
    if (disabled) setTagToDisable('');
  };

  const addNote = async () => {
    if (!noteText.trim()) return;
    const saved = await metadataRequest(CALL_NOTES_URL, 'POST', {
      call_uuid: call.uuid,
      text: noteText,
      offset_seconds: noteOffset
    });
    if (saved) {
      setNoteText('');
      setNoteOffset('');
    }
  };

  const retrySummary = async () => {
    if (!call?.uuid || !csrf) return;
    setRetryingSummary(true);
    setSummaryRetryError(false);
    setEnrichment((current) => (current ? { ...current, summary_state: 'processing' } : current));
    try {
      const response = await fetch(SUMMARY_RETRY_URL, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf },
        body: JSON.stringify({ id: call.uuid })
      });
      if (!response.ok) throw new Error('summary_retry_failed');
      const refreshed = await fetch(`${CALL_ENRICHMENT_URL}?id=${encodeURIComponent(call.uuid)}`, { credentials: 'same-origin' });
      if (!refreshed.ok) throw new Error('summary_refresh_failed');
      const payload = await refreshed.json();
      setEnrichment(payload?.transcript || null);
    } catch {
      setSummaryRetryError(true);
    } finally {
      setRetryingSummary(false);
    }
  };

  return (
    <Drawer anchor="right" open={Boolean(call)} onClose={onClose} PaperProps={{ sx: { width: { xs: 1, sm: 480 }, p: 3 } }}>
      {call && (
        <Stack sx={{ gap: 2 }}>
          <Stack direction="row" sx={{ alignItems: 'center', justifyContent: 'space-between' }}>
            <Typography variant="h5">
              <FormattedMessage id="details.title" />
            </Typography>
            <IconButton onClick={onClose} aria-label={intl.formatMessage({ id: 'details.close' })}>
              <CloseOutlined />
            </IconButton>
          </Stack>
          <Stack direction="row" sx={{ gap: 1, alignItems: 'center' }}>
            <Chip
              size="small"
              variant="combined"
              color={STATUS_COLOR[call.status] ?? 'secondary'}
              label={intl.formatMessage({ id: `callState.${call.status}`, defaultMessage: call.status })}
            />
            <Typography variant="body2">
              <FormattedMessage id={`direction.${call.direction || 'unknown'}`} />
            </Typography>
          </Stack>
          <Divider />
          <Detail
            label={<FormattedMessage id="table.caller" />}
            value={`${call.caller_id_name || ''} ${call.caller_id_number || ''}`.trim()}
          />
          <Detail label={<FormattedMessage id="table.destination" />} value={call.destination_number} />
          <Detail
            label={<FormattedMessage id="details.started" />}
            value={call.start_stamp ? new Date(call.start_stamp).toLocaleString(intl.locale) : null}
          />
          <Detail
            label={<FormattedMessage id="details.answered" />}
            value={call.answer_stamp ? new Date(call.answer_stamp).toLocaleString(intl.locale) : null}
          />
          <Detail
            label={<FormattedMessage id="details.ended" />}
            value={call.end_stamp ? new Date(call.end_stamp).toLocaleString(intl.locale) : null}
          />
          <Detail label={<FormattedMessage id="table.wait" />} value={formatSeconds(call.waitsec)} />
          <Detail label={<FormattedMessage id="table.talk" />} value={formatSeconds(call.billsec)} />
          <Detail label={<FormattedMessage id="details.totalDuration" />} value={formatSeconds(call.duration)} />
          <Detail label={<FormattedMessage id="details.hangupCause" />} value={call.hangup_cause} />
          <Detail label={<FormattedMessage id="details.sipDisposition" />} value={call.sip_hangup_disposition} />
          {call.recording && (
            <>
              <Divider />
              <Typography variant="h6">
                <FormattedMessage id="history.recording" />
              </Typography>
              <RecordingPlayer callUuid={call.uuid} allowDownload={allowDownload} seekRequest={seekRequest} />
            </>
          )}
          {(metadata.capabilities.tag_assign || metadata.capabilities.tag_edit || metadata.tags.length > 0) && (
            <>
              <Divider />
              <Typography variant="h6">
                <FormattedMessage id="metadata.tags" />
              </Typography>
              <Stack direction="row" sx={{ gap: 1, flexWrap: 'wrap' }}>
                {metadata.tags.map((tag) => (
                  <Chip
                    key={tag.uuid}
                    size="small"
                    color={tag.color || 'primary'}
                    label={tag.name}
                    onDelete={
                      metadata.capabilities.tag_assign && !metadataBusy
                        ? () => metadataRequest(CALL_TAGS_URL, 'POST', { action: 'unassign', call_uuid: call.uuid, tag_uuid: tag.uuid })
                        : undefined
                    }
                  />
                ))}
                {metadata.tags.length === 0 && (
                  <Typography variant="body2" color="text.secondary">
                    <FormattedMessage id="metadata.tagsEmpty" />
                  </Typography>
                )}
              </Stack>
              {metadata.capabilities.tag_assign && (
                <Stack direction={{ xs: 'column', sm: 'row' }} sx={{ gap: 1 }}>
                  <TextField
                    select
                    size="small"
                    fullWidth
                    label={intl.formatMessage({ id: 'metadata.selectTag' })}
                    value={selectedTag}
                    onChange={(event) => setSelectedTag(event.target.value)}
                  >
                    {metadata.available_tags
                      .filter((tag) => !metadata.tags.some((assigned) => assigned.uuid === tag.uuid))
                      .map((tag) => (
                        <MenuItem key={tag.uuid} value={tag.uuid}>
                          {tag.name}
                        </MenuItem>
                      ))}
                  </TextField>
                  <Button variant="outlined" disabled={!selectedTag || metadataBusy} onClick={assignTag}>
                    <FormattedMessage id="metadata.assignTag" />
                  </Button>
                </Stack>
              )}
              {metadata.capabilities.tag_edit && (
                <Stack direction="row" sx={{ gap: 1 }}>
                  <TextField
                    size="small"
                    fullWidth
                    inputProps={{ maxLength: 80 }}
                    label={intl.formatMessage({ id: 'metadata.newTag' })}
                    value={newTagName}
                    onChange={(event) => setNewTagName(event.target.value)}
                  />
                  <Button variant="outlined" disabled={!newTagName.trim() || metadataBusy} onClick={createAndAssignTag}>
                    <FormattedMessage id="metadata.createTag" />
                  </Button>
                </Stack>
              )}
              {metadata.capabilities.tag_edit && (
                <Stack direction={{ xs: 'column', sm: 'row' }} sx={{ gap: 1 }}>
                  <TextField
                    select
                    size="small"
                    fullWidth
                    label={intl.formatMessage({ id: 'metadata.disableTag' })}
                    value={tagToDisable}
                    onChange={(event) => setTagToDisable(event.target.value)}
                  >
                    {metadata.available_tags.map((tag) => (
                      <MenuItem key={tag.uuid} value={tag.uuid}>
                        {tag.name}
                      </MenuItem>
                    ))}
                  </TextField>
                  <Button color="warning" variant="outlined" disabled={!tagToDisable || metadataBusy} onClick={disableTag}>
                    <FormattedMessage id="metadata.disableTagAction" />
                  </Button>
                </Stack>
              )}
            </>
          )}
          {(metadata.capabilities.note_add || metadata.notes.length > 0) && (
            <>
              <Divider />
              <Typography variant="h6">
                <FormattedMessage id="metadata.notes" />
              </Typography>
              <Stack sx={{ gap: 1 }}>
                {metadata.notes.map((note) => (
                  <Stack key={note.uuid} sx={{ gap: 0.5, p: 1.25, bgcolor: 'action.hover', borderRadius: 1 }}>
                    {editingNote?.uuid === note.uuid ? (
                      <TextField
                        multiline
                        size="small"
                        value={editingNote.text}
                        inputProps={{ maxLength: 2000 }}
                        onChange={(event) => setEditingNote({ ...editingNote, text: event.target.value })}
                      />
                    ) : (
                      <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>
                        {note.text}
                      </Typography>
                    )}
                    <Typography variant="caption" color="text.secondary">
                      {note.author || '—'} · {new Date(note.created_at).toLocaleString(intl.locale)}
                    </Typography>
                    <Stack direction="row" sx={{ gap: 1 }}>
                      {note.offset_seconds !== null && (
                        <Button
                          size="small"
                          disabled={!call.recording}
                          onClick={() => setSeekRequest({ seconds: note.offset_seconds, nonce: Date.now() })}
                        >
                          {formatSeconds(Math.floor(note.offset_seconds))}
                        </Button>
                      )}
                      {note.own &&
                        metadata.capabilities.note_edit &&
                        (editingNote?.uuid === note.uuid ? (
                          <Button
                            size="small"
                            disabled={!editingNote.text.trim() || metadataBusy}
                            onClick={async () => {
                              if (await metadataRequest(CALL_NOTES_URL, 'PATCH', { note_uuid: note.uuid, text: editingNote.text }))
                                setEditingNote(null);
                            }}
                          >
                            <FormattedMessage id="common.save" />
                          </Button>
                        ) : (
                          <Button size="small" onClick={() => setEditingNote({ uuid: note.uuid, text: note.text })}>
                            <FormattedMessage id="common.edit" />
                          </Button>
                        ))}
                      {note.own && metadata.capabilities.note_delete && (
                        <Button
                          size="small"
                          color="error"
                          disabled={metadataBusy}
                          onClick={() => metadataRequest(CALL_NOTES_URL, 'DELETE', { note_uuid: note.uuid })}
                        >
                          <FormattedMessage id="common.delete" />
                        </Button>
                      )}
                    </Stack>
                  </Stack>
                ))}
              </Stack>
              {metadata.capabilities.note_add && (
                <Stack sx={{ gap: 1 }}>
                  <TextField
                    multiline
                    minRows={2}
                    inputProps={{ maxLength: 2000 }}
                    label={intl.formatMessage({ id: 'metadata.noteText' })}
                    value={noteText}
                    onChange={(event) => setNoteText(event.target.value)}
                  />
                  <TextField
                    size="small"
                    type="number"
                    label={intl.formatMessage({ id: 'metadata.noteOffset' })}
                    value={noteOffset}
                    inputProps={{ min: 0, max: call.duration || 86400 }}
                    onChange={(event) => setNoteOffset(event.target.value)}
                  />
                  <Button variant="outlined" disabled={!noteText.trim() || metadataBusy} onClick={addNote}>
                    <FormattedMessage id="metadata.addNote" />
                  </Button>
                </Stack>
              )}
            </>
          )}
          {metadataError && (
            <Typography variant="body2" color="error">
              <FormattedMessage id="metadata.error" />
            </Typography>
          )}
          <Divider />
          <Typography variant="h6">
            <FormattedMessage id="transcript.title" />
          </Typography>
          {loadingEnrichment && <CircularProgress size={22} />}
          {!loadingEnrichment && (!enrichment || enrichment.state === 'unavailable') && (
            <Typography variant="body2" sx={{ color: 'text.secondary' }}>
              <FormattedMessage id="transcript.unavailable" />
            </Typography>
          )}
          {!loadingEnrichment && enrichment && ['pending', 'processing'].includes(enrichment.state) && (
            <Typography variant="body2" sx={{ color: 'text.secondary' }}>
              <FormattedMessage id={`transcript.${enrichment.state}`} />
            </Typography>
          )}
          {!loadingEnrichment && enrichment?.state === 'failed' && (
            <Typography variant="body2" color="error">
              <FormattedMessage id="transcript.failed" />
            </Typography>
          )}
          {enrichment?.summary && (
            <Stack sx={{ gap: 0.5, p: 1.5, bgcolor: 'action.hover', borderRadius: 1 }}>
              <Typography variant="subtitle2">
                <FormattedMessage id="transcript.summary" />
              </Typography>
              <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>
                {enrichment.summary}
              </Typography>
            </Stack>
          )}
          {enrichment?.state === 'completed' && enrichment?.summary_state !== 'completed' && (
            <Typography variant="body2" color={enrichment?.summary_state === 'failed' ? 'error' : 'text.secondary'}>
              <FormattedMessage id={`summaryState.${enrichment?.summary_state || 'unavailable'}`} />
            </Typography>
          )}
          {summaryRetryError && (
            <Typography variant="body2" color="error">
              <FormattedMessage id="summaryRetry.failed" />
            </Typography>
          )}
          {allowSummaryRetry && enrichment?.state === 'completed' && (
            <Button
              variant="outlined"
              size="small"
              disabled={retryingSummary || enrichment?.summary_state === 'processing'}
              onClick={retrySummary}
            >
              <FormattedMessage id={retryingSummary ? 'summaryRetry.processing' : 'summaryRetry.action'} />
            </Button>
          )}
          {enrichment?.segments?.length > 0 && (
            <Stack sx={{ gap: 1, maxHeight: 320, overflowY: 'auto' }}>
              {enrichment.segments.map((segment, index) => (
                <Button
                  key={`${segment.start}-${segment.speaker}-${index}`}
                  variant="text"
                  color="inherit"
                  disabled={!call.recording}
                  onClick={() => setSeekRequest({ seconds: segment.start, nonce: Date.now() })}
                  sx={{ alignItems: 'flex-start', justifyContent: 'flex-start', textAlign: 'left', textTransform: 'none', p: 1 }}
                >
                  <Stack sx={{ gap: 0.25 }}>
                    <Typography variant="caption" sx={{ color: 'primary.main' }}>
                      {formatSeconds(Math.floor(segment.start))} ·{' '}
                      {intl.formatMessage({ id: 'transcript.speaker' }, { speaker: Number(segment.speaker) + 1 })}
                    </Typography>
                    <Typography variant="body2">{segment.text}</Typography>
                  </Stack>
                </Button>
              ))}
            </Stack>
          )}
          <Divider />
          <Typography variant="caption" sx={{ color: 'text.secondary', wordBreak: 'break-all' }}>
            UUID: {call.uuid}
          </Typography>
        </Stack>
      )}
    </Drawer>
  );
}

CallDetailsDrawer.propTypes = {
  call: PropTypes.object,
  onClose: PropTypes.func.isRequired,
  allowDownload: PropTypes.bool,
  allowSummaryRetry: PropTypes.bool,
  csrf: PropTypes.string
};
