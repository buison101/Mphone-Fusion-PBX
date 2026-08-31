import { useCallback, useEffect, useMemo, useState } from 'react';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Checkbox from '@mui/material/Checkbox';
import Chip from '@mui/material/Chip';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import ListItemText from '@mui/material/ListItemText';
import MenuItem from '@mui/material/MenuItem';
import Select from '@mui/material/Select';
import Switch from '@mui/material/Switch';
import FormControlLabel from '@mui/material/FormControlLabel';
import TextField from '@mui/material/TextField';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Typography from '@mui/material/Typography';
import { FormattedMessage, useIntl } from 'react-intl';
import MainCard from 'components/MainCard';
import ContentState from 'components/states/ContentState';
import useSession from 'hooks/useSession';
import { GREETING_RECORDING_URL, SIMPLE_CALL_ROUTING_URL } from 'config';

export default function SimpleCallRouting() {
  const intl = useIntl();
  const { session } = useSession();
  const [data, setData] = useState(null);
  const [members, setMembers] = useState({});
  const [callerIds, setCallerIds] = useState({});
  const [flows, setFlows] = useState({});
  const [busy, setBusy] = useState('');
  const [error, setError] = useState('');
  const load = useCallback(async () => {
    const response = await fetch(SIMPLE_CALL_ROUTING_URL, { credentials: 'same-origin' });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(payload.error || 'service_unavailable');
    setData(payload);
    setMembers(Object.fromEntries((payload.assignments || []).map((row) => [row.did_assignment_uuid,
      row.desired_state?.extension_uuids || []])));
    setCallerIds(Object.fromEntries((payload.extensions || []).map((row) => [row.extension_uuid,
      row.preference?.did_assignment_uuid || ''])));
    const normalizeMappings = (mappings = {}) => Object.fromEntries(Object.entries(mappings).map(([digit, target]) => {
      if (typeof target === 'string') return [digit, [target]];
      if (Array.isArray(target)) return [digit, target];
      return [digit, Array.isArray(target?.member_extension_uuids) ? target.member_extension_uuids : []];
    }));
    setFlows(Object.fromEntries((payload.assignments || []).map((row) => [row.did_assignment_uuid, {
      greeting: ['simple_greeting', 'simple_keypad'].includes(row.route_type), keypad: row.route_type === 'simple_keypad',
      recording: row.desired_state?.greeting_recording_uuid || '', mappings: normalizeMappings(row.desired_state?.keypad_mappings)
    }])));
  }, []);
  useEffect(() => { load().catch((err) => setError(err.message)); }, [load]);
  const extensionMap = useMemo(() => new Map((data?.extensions || []).map((row) => [row.extension_uuid, row])), [data]);
  const save = async (assignment) => {
    setBusy(assignment.did_assignment_uuid); setError('');
    try {
      const response = await fetch(SIMPLE_CALL_ROUTING_URL, { method: 'POST', credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session?.csrf || '' },
        body: JSON.stringify({ action: 'save_apply', did_uuid: assignment.did_uuid,
          did_assignment_uuid: assignment.did_assignment_uuid,
          expected_assignment_revision: assignment.assignment_revision,
          expected_management_revision: assignment.management_revision,
          extension_uuids: members[assignment.did_assignment_uuid] || [], outbound_assignments: callerIds,
          route_type: flows[assignment.did_assignment_uuid]?.keypad ? 'simple_keypad' : flows[assignment.did_assignment_uuid]?.greeting ? 'simple_greeting' : 'simple_direct',
          greeting_recording_uuid: flows[assignment.did_assignment_uuid]?.recording || '',
          keypad_mappings: flows[assignment.did_assignment_uuid]?.keypad ? (flows[assignment.did_assignment_uuid]?.mappings || {}) : {},
          operation_key: crypto.randomUUID() }) });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable');
      await load();
    } catch (err) { setError(err.message); } finally { setBusy(''); }
  };
  const upload = async (assignment, file) => {
    if (!file) return; setBusy(assignment.did_assignment_uuid); setError('');
    try { const form = new FormData(); form.append('audio', file); form.append('name', file.name.replace(/\.[^.]+$/, ''));
      const response = await fetch(GREETING_RECORDING_URL, { method: 'POST', credentials: 'same-origin',
        headers: { 'X-CSRF-Token': session?.csrf || '' }, body: form }); const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable'); await load();
      setFlows((value) => ({ ...value, [assignment.did_assignment_uuid]: { ...(value[assignment.did_assignment_uuid] || {}), greeting: true, recording: payload.recording_uuid } }));
    } catch (err) { setError(err.message); } finally { setBusy(''); }
  };
  if (!session?.identity || !session?.workspace?.active) return <ContentState state="forbidden" title={<FormattedMessage id="customer.workspaceRequired" />} />;
  if (session?.membership?.role !== 'owner') return <ContentState state="forbidden" title={<FormattedMessage id="routing.ownerRequired" />} />;
  if (!data) return error ? <Alert severity="error">{error}</Alert> : <ContentState loading />;
  return <Stack spacing={2}>
    <Typography variant="h4"><FormattedMessage id="routing.title" /></Typography>
    <Alert severity="info"><FormattedMessage id="routing.phase3Notice" /></Alert>
    {error && <Alert severity="error"><FormattedMessage id={`routing.error.${error}`} defaultMessage={error} /></Alert>}
    <MainCard title={<FormattedMessage id="routing.phoneNumbers" />}><Stack spacing={2}>
      {!data.assignments?.length && <Typography color="text.secondary"><FormattedMessage id="routing.noNumbers" /></Typography>}
      {(data.assignments || []).map((assignment) => {
        const domainExtensions = data.extensions.filter((row) => row.fusion_domain_uuid === assignment.fusion_domain_uuid && row.enabled);
        const selected = members[assignment.did_assignment_uuid] || [];
        const flow = flows[assignment.did_assignment_uuid] || { greeting: false, keypad: false, recording: '', mappings: {} };
        const recordings = (data.recordings || []).filter((row) => row.domain_uuid === assignment.fusion_domain_uuid);
        return <Stack key={assignment.did_assignment_uuid} spacing={2} sx={{ borderBottom: 1, borderColor: 'divider', pb: 2 }}><Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ md: 'center' }}>
          <Stack sx={{ minWidth: 210 }}><Typography fontWeight={600}>{assignment.display_number}</Typography>
            <Typography variant="caption">{assignment.canonical_e164}</Typography></Stack>
          <FormControl fullWidth><InputLabel><FormattedMessage id="routing.defaultGroup" /></InputLabel>
            <Select multiple value={selected} label={intl.formatMessage({ id: 'routing.defaultGroup' })}
              onChange={(event) => setMembers((value) => ({ ...value, [assignment.did_assignment_uuid]: event.target.value }))}
              renderValue={(values) => values.map((uuid) => extensionMap.get(uuid)?.extension).filter(Boolean).join(', ')}>
              {domainExtensions.map((extension) => <MenuItem key={extension.extension_uuid} value={extension.extension_uuid}>
                <Checkbox checked={selected.includes(extension.extension_uuid)} /><ListItemText primary={extension.extension} secondary={extension.effective_caller_id_name} />
              </MenuItem>)}</Select></FormControl>
          <Chip label={assignment.management_mode} color={assignment.management_mode === 'portal_simple' ? 'success' : 'warning'} />
          <Button variant="contained" disabled={busy !== '' || selected.length === 0 || assignment.management_mode !== 'portal_simple'} onClick={() => save(assignment)}>
            <FormattedMessage id="routing.saveApply" /></Button>
        </Stack><Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ md: 'center' }}>
          <FormControlLabel control={<Switch checked={flow.greeting} onChange={(e) => setFlows((v) => ({ ...v, [assignment.did_assignment_uuid]: { ...flow, greeting: e.target.checked, keypad: e.target.checked ? flow.keypad : false } }))} />} label={<FormattedMessage id="routing.greeting" />} />
          <FormControl sx={{ minWidth: 220 }} disabled={!flow.greeting}><InputLabel><FormattedMessage id="routing.recording" /></InputLabel><Select value={flow.recording} label={intl.formatMessage({ id: 'routing.recording' })} onChange={(e) => setFlows((v) => ({ ...v, [assignment.did_assignment_uuid]: { ...flow, recording: e.target.value } }))}>{recordings.map((recording) => <MenuItem key={recording.recording_uuid} value={recording.recording_uuid}>{recording.recording_name}</MenuItem>)}</Select></FormControl>
          <Button component="label" variant="outlined" disabled={busy !== ''}><FormattedMessage id="routing.upload" /><input hidden type="file" accept="audio/wav,audio/mpeg,audio/ogg" onChange={(e) => upload(assignment, e.target.files?.[0])} /></Button>
          {flow.recording && <Button component="a" target="_blank" href={`${GREETING_RECORDING_URL}?id=${encodeURIComponent(flow.recording)}`}><FormattedMessage id="routing.preview" /></Button>}
          <FormControlLabel control={<Switch checked={flow.keypad} disabled={!flow.greeting || !flow.recording} onChange={(e) => setFlows((v) => ({ ...v, [assignment.did_assignment_uuid]: { ...flow, keypad: e.target.checked } }))} />} label={<FormattedMessage id="routing.keypad" />} />
        </Stack>{flow.keypad && <Stack direction="row" useFlexGap flexWrap="wrap" gap={1}>{Array.from({ length: 10 }, (_, digit) => {
          const digitMembers = flow.mappings?.[digit] || [];
          return <FormControl key={digit} size="small" sx={{ width: 190 }}><InputLabel>{digit}</InputLabel><Select multiple value={digitMembers} label={`${digit}`}
            onChange={(e) => setFlows((v) => ({ ...v, [assignment.did_assignment_uuid]: { ...flow, mappings: { ...flow.mappings, [digit]: e.target.value } } }))}
            renderValue={(values) => values.map((uuid) => extensionMap.get(uuid)?.extension).filter(Boolean).join(', ')}>
            {domainExtensions.map((extension) => <MenuItem key={extension.extension_uuid} value={extension.extension_uuid}>
              <Checkbox checked={digitMembers.includes(extension.extension_uuid)} /><ListItemText primary={extension.extension} secondary={extension.effective_caller_id_name} />
            </MenuItem>)}</Select></FormControl>;
        })}</Stack>}
        <Alert severity="success"><FormattedMessage id={flow.keypad ? 'routing.summary.keypad' : flow.greeting ? 'routing.summary.greeting' : 'routing.summary.direct'} values={{ members: selected.map((uuid) => extensionMap.get(uuid)?.extension).filter(Boolean).join(', ') }} /></Alert></Stack>;
      })}
    </Stack></MainCard>
    <MainCard title={<FormattedMessage id="routing.extensions" />}><Table size="small"><TableHead><TableRow>
      <TableCell><FormattedMessage id="routing.extension" /></TableCell><TableCell><FormattedMessage id="routing.inboundSummary" /></TableCell>
      <TableCell><FormattedMessage id="routing.outboundCallerId" /></TableCell></TableRow></TableHead><TableBody>
      {data.extensions.map((extension) => {
        const inbound = data.assignments.filter((assignment) => (members[assignment.did_assignment_uuid] || []).includes(extension.extension_uuid));
        const options = data.outbound_caller_ids.filter((item) => item.fusion_domain_uuid === extension.fusion_domain_uuid);
        return <TableRow key={extension.extension_uuid}><TableCell>{extension.extension}</TableCell>
          <TableCell>{inbound.map((item) => item.display_number).join(', ') || '—'}</TableCell><TableCell>
          <FormControl fullWidth size="small"><Select displayEmpty value={callerIds[extension.extension_uuid] || ''}
            onChange={(event) => setCallerIds((value) => ({ ...value, [extension.extension_uuid]: event.target.value }))}>
            <MenuItem value=""><FormattedMessage id="routing.callerIdNone" /></MenuItem>
            {options.map((item) => <MenuItem key={item.did_assignment_uuid} value={item.did_assignment_uuid}>{item.display_number}</MenuItem>)}
          </Select></FormControl></TableCell></TableRow>;
      })}
    </TableBody></Table></MainCard>
  </Stack>;
}
