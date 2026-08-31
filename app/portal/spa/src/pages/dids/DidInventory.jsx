import { useCallback, useEffect, useMemo, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Checkbox from '@mui/material/Checkbox';
import Chip from '@mui/material/Chip';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import FormControl from '@mui/material/FormControl';
import FormControlLabel from '@mui/material/FormControlLabel';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';
import Select from '@mui/material/Select';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import MainCard from 'components/MainCard';
import ContentState from 'components/states/ContentState';
import useSession from 'hooks/useSession';
import { DID_INVENTORY_URL } from 'config';

const operationKey = () => globalThis.crypto?.randomUUID?.() || `${Date.now()}-${Math.random()}`;

export default function DidInventory() {
  const intl = useIntl();
  const { session } = useSession();
  const [data, setData] = useState({ dids: [], customers: [], extensions: [] });
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [createOpen, setCreateOpen] = useState(false);
  const [assignDid, setAssignDid] = useState(null);
  const [assignAction, setAssignAction] = useState('assign');
  const [transition, setTransition] = useState(null);
  const [transitionReason, setTransitionReason] = useState('');
  const [basicRelease, setBasicRelease] = useState(null);
  const [createForm, setCreateForm] = useState({ canonical_e164: '', display_number: '', country_code: 'VN', provider_reference: '', provider_service_status: 'active', inbound: true, outbound_caller_id: true, reason: '' });
  const [assignForm, setAssignForm] = useState({ customer_key: '', extension_uuids: [], reason: '' });

  const request = useCallback(async (body, method = 'POST') => {
    const response = await fetch(method === 'GET' ? `${DID_INVENTORY_URL}?action=list` : DID_INVENTORY_URL, {
      method,
      credentials: 'same-origin',
      headers: method === 'POST' ? { 'Content-Type': 'application/json', 'X-CSRF-Token': session?.csrf || '' } : {},
      body: method === 'POST' ? JSON.stringify(body) : undefined
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(payload.error || 'service_unavailable');
    return payload;
  }, [session?.csrf]);

  const load = useCallback(async () => {
    try { setData(await request(null, 'GET')); setError(''); } catch (err) { setError(err.message); }
  }, [request]);
  useEffect(() => { if (session?.user_management?.superadmin) load(); }, [load, session?.user_management?.superadmin]);

  const selectedCustomer = useMemo(() => data.customers.find((item) => `${item.customer_uuid}:${item.fusion_domain_uuid}` === assignForm.customer_key), [assignForm.customer_key, data.customers]);
  const availableExtensions = useMemo(() => selectedCustomer ? data.extensions.filter((item) => item.customer_uuid === selectedCustomer.customer_uuid && item.fusion_domain_uuid === selectedCustomer.fusion_domain_uuid && item.enabled) : [], [data.extensions, selectedCustomer]);

  const mutate = async (body, after) => {
    setBusy(true); setError('');
    try { await request(body); await load(); after?.(); } catch (err) { setError(err.message); } finally { setBusy(false); }
  };
  const createDid = () => mutate({ action: 'create', ...createForm }, () => setCreateOpen(false));
  const reserve = (did) => mutate({ action: 'reserve', did_uuid: did.did_uuid, expected_inventory_revision: Number(did.revision), operation_key: operationKey(), reason: intl.formatMessage({ id: 'dids.reserveReason' }) });
  const assign = () => {
    if (!assignDid || !selectedCustomer) return;
    mutate({ action: assignAction, did_uuid: assignDid.did_uuid, did_assignment_uuid: assignDid.did_assignment_uuid, expected_assignment_revision: Number(assignDid.assignment_revision || 0), expected_management_revision: Number(assignDid.management_revision || 0), customer_uuid: selectedCustomer.customer_uuid, fusion_domain_uuid: selectedCustomer.fusion_domain_uuid, extension_uuids: assignForm.extension_uuids, operation_key: operationKey(), reason: assignForm.reason }, () => setAssignDid(null));
  };
  const applyTransition = () => {
    if (!transition) return;
    mutate({ action: transition.action, did_uuid: transition.did.did_uuid, did_assignment_uuid: transition.did.did_assignment_uuid, expected_assignment_revision: Number(transition.did.assignment_revision), expected_management_revision: Number(transition.did.management_revision), operation_key: operationKey(), reason: transitionReason }, () => setTransition(null));
  };
  const inspectRelease = async (did) => {
    setBusy(true); setError('');
    try {
      const inspection = await request({ action: 'advanced_inspect', did_assignment_uuid: did.did_assignment_uuid });
      setBasicRelease({ did, inspection, extension_uuids: [], reason: '' });
    } catch (err) { setError(err.message); } finally { setBusy(false); }
  };
  const releaseToSimple = () => {
    if (!basicRelease) return;
    mutate({ action: 'release_to_simple', did_uuid: basicRelease.did.did_uuid,
      did_assignment_uuid: basicRelease.did.did_assignment_uuid,
      expected_assignment_revision: Number(basicRelease.did.assignment_revision),
      expected_management_revision: Number(basicRelease.did.management_revision),
      extension_uuids: basicRelease.extension_uuids, operation_key: operationKey(), reason: basicRelease.reason },
    () => setBasicRelease(null));
  };

  if (!session?.user_management?.superadmin) return <ContentState title={<FormattedMessage id="dids.forbidden" />} />;
  return <MainCard title={<FormattedMessage id="dids.title" />} secondary={<Button variant="contained" onClick={() => setCreateOpen(true)}><FormattedMessage id="dids.add" /></Button>}>
    <Stack spacing={2}>
      {error && <Alert severity="error"><FormattedMessage id={`dids.error.${error}`} defaultMessage={error} /></Alert>}
      <Alert severity="info"><FormattedMessage id="dids.phase2Notice" /></Alert>
      <TableContainer><Table size="small">
        <TableHead><TableRow><TableCell><FormattedMessage id="dids.number" /></TableCell><TableCell><FormattedMessage id="dids.service" /></TableCell><TableCell><FormattedMessage id="dids.assignment" /></TableCell><TableCell><FormattedMessage id="dids.route" /></TableCell><TableCell align="right"><FormattedMessage id="common.actions" /></TableCell></TableRow></TableHead>
        <TableBody>{data.dids.map((did) => <TableRow key={did.did_uuid}>
          <TableCell><Typography variant="subtitle2">{did.display_number}</Typography><Typography variant="caption" color="text.secondary">{did.canonical_e164}</Typography></TableCell>
          <TableCell><Stack direction="row" spacing={1}><Chip size="small" label={did.inventory_status} /><Chip size="small" variant="outlined" label={did.provider_service_status} /></Stack></TableCell>
          <TableCell>{did.customer_name || '—'}{did.assignment_status && <Typography variant="caption" display="block">{did.assignment_status}</Typography>}</TableCell>
          <TableCell>{did.management_mode || '—'}{did.route_status && <Typography variant="caption" display="block">{did.route_status}</Typography>}</TableCell>
          <TableCell align="right"><Stack direction="row" spacing={1} justifyContent="flex-end">
            {did.inventory_status === 'available' && <Button size="small" disabled={busy} onClick={() => reserve(did)}><FormattedMessage id="dids.reserve" /></Button>}
            {did.inventory_status === 'reserved' && !did.did_assignment_uuid && <Button size="small" variant="contained" disabled={busy} onClick={() => { setAssignAction('assign'); setAssignDid(did); setAssignForm({ customer_key: '', extension_uuids: [], reason: '' }); }}><FormattedMessage id="dids.assign" /></Button>}
            {did.assignment_status === 'active' && <Button size="small" disabled={busy} onClick={() => { setTransition({ action: 'suspend', did }); setTransitionReason(''); }}><FormattedMessage id="dids.suspend" /></Button>}
            {did.assignment_status === 'suspended' && <Button size="small" disabled={busy} onClick={() => { setTransition({ action: 'resume', did }); setTransitionReason(''); }}><FormattedMessage id="dids.resume" /></Button>}
            {['active', 'suspended'].includes(did.assignment_status) && <Button size="small" color="error" disabled={busy} onClick={() => { setTransition({ action: 'release', did }); setTransitionReason(''); }}><FormattedMessage id="dids.release" /></Button>}
            {['active', 'suspended'].includes(did.assignment_status) && <Button size="small" disabled={busy} onClick={() => { setAssignAction('transfer'); setAssignDid(did); setAssignForm({ customer_key: '', extension_uuids: [], reason: '' }); }}><FormattedMessage id="dids.transfer" /></Button>}
            {did.assignment_status === 'active' && did.management_mode === 'portal_simple' && <Button size="small" color="warning" disabled={busy} onClick={() => { setTransition({ action: 'takeover_advanced', did }); setTransitionReason(''); }}><FormattedMessage id="dids.takeoverAdvanced" /></Button>}
            {did.assignment_status === 'active' && did.management_mode === 'mphone_advanced' && <Button size="small" color="success" disabled={busy} onClick={() => inspectRelease(did)}><FormattedMessage id="dids.releaseToSimple" /></Button>}
          </Stack></TableCell>
        </TableRow>)}</TableBody>
      </Table></TableContainer>
      {data.dids.length === 0 && <ContentState title={<FormattedMessage id="dids.empty" />} />}
    </Stack>

    <Dialog open={createOpen} onClose={() => !busy && setCreateOpen(false)} fullWidth maxWidth="sm"><DialogTitle><FormattedMessage id="dids.add" /></DialogTitle><DialogContent><Stack spacing={2} sx={{ mt: 1 }}>
      <TextField label="E.164" value={createForm.canonical_e164} onChange={(e) => setCreateForm((v) => ({ ...v, canonical_e164: e.target.value }))} placeholder="+842873001234" />
      <TextField label={<FormattedMessage id="dids.displayNumber" />} value={createForm.display_number} onChange={(e) => setCreateForm((v) => ({ ...v, display_number: e.target.value }))} />
      <TextField label={<FormattedMessage id="dids.country" />} value={createForm.country_code} onChange={(e) => setCreateForm((v) => ({ ...v, country_code: e.target.value.toUpperCase() }))} />
      <TextField label={<FormattedMessage id="dids.providerReference" />} helperText={<FormattedMessage id="dids.providerReferenceHelp" />}
        value={createForm.provider_reference} onChange={(e) => setCreateForm((v) => ({ ...v, provider_reference: e.target.value }))} />
      <FormControl><InputLabel><FormattedMessage id="dids.providerStatus" /></InputLabel><Select label={<FormattedMessage id="dids.providerStatus" />} value={createForm.provider_service_status} onChange={(e) => setCreateForm((v) => ({ ...v, provider_service_status: e.target.value }))}>{['provisioning', 'active', 'suspended', 'porting_out', 'disconnected'].map((status) => <MenuItem key={status} value={status}>{status}</MenuItem>)}</Select></FormControl>
      <FormControlLabel control={<Checkbox checked={createForm.inbound} onChange={(e) => setCreateForm((v) => ({ ...v, inbound: e.target.checked }))} />} label={<FormattedMessage id="dids.inbound" />} />
      <FormControlLabel control={<Checkbox checked={createForm.outbound_caller_id} onChange={(e) => setCreateForm((v) => ({ ...v, outbound_caller_id: e.target.checked }))} />} label={<FormattedMessage id="dids.outboundCallerId" />} />
      <TextField label={<FormattedMessage id="dids.reason" />} value={createForm.reason} onChange={(e) => setCreateForm((v) => ({ ...v, reason: e.target.value }))} />
    </Stack></DialogContent><DialogActions><Button onClick={() => setCreateOpen(false)}><FormattedMessage id="common.cancel" /></Button><Button variant="contained" disabled={busy} onClick={createDid}><FormattedMessage id="common.save" /></Button></DialogActions></Dialog>

    <Dialog open={Boolean(assignDid)} onClose={() => !busy && setAssignDid(null)} fullWidth maxWidth="sm"><DialogTitle><FormattedMessage id={assignAction === 'transfer' ? 'dids.transferTitle' : 'dids.assignTitle'} values={{ number: assignDid?.display_number || '' }} /></DialogTitle><DialogContent><Stack spacing={2} sx={{ mt: 1 }}>
      <FormControl><InputLabel><FormattedMessage id="dids.customerDomain" /></InputLabel><Select label={<FormattedMessage id="dids.customerDomain" />} value={assignForm.customer_key} onChange={(e) => setAssignForm({ customer_key: e.target.value, extension_uuids: [], reason: assignForm.reason })}>{data.customers.map((customer) => <MenuItem key={`${customer.customer_uuid}:${customer.fusion_domain_uuid}`} value={`${customer.customer_uuid}:${customer.fusion_domain_uuid}`}>{customer.display_name} · {customer.fusion_domain_name}</MenuItem>)}</Select></FormControl>
      <FormControl><InputLabel><FormattedMessage id="dids.initialExtensions" /></InputLabel><Select multiple label={<FormattedMessage id="dids.initialExtensions" />} value={assignForm.extension_uuids} onChange={(e) => setAssignForm((v) => ({ ...v, extension_uuids: e.target.value }))}>{availableExtensions.map((extension) => <MenuItem key={extension.extension_uuid} value={extension.extension_uuid}>{extension.extension} · {extension.effective_caller_id_name || ''}</MenuItem>)}</Select></FormControl>
      <TextField required label={<FormattedMessage id="dids.reason" />} value={assignForm.reason} onChange={(e) => setAssignForm((v) => ({ ...v, reason: e.target.value }))} />
      <Alert severity="warning"><FormattedMessage id={assignAction === 'transfer' ? 'dids.transferWarning' : 'dids.assignWarning'} /></Alert>
    </Stack></DialogContent><DialogActions><Button onClick={() => setAssignDid(null)}><FormattedMessage id="common.cancel" /></Button><Button variant="contained" disabled={busy || !selectedCustomer || assignForm.extension_uuids.length === 0 || assignForm.reason.trim().length < 2 || (assignAction === 'transfer' && selectedCustomer.customer_uuid === assignDid?.customer_uuid && selectedCustomer.fusion_domain_uuid === assignDid?.fusion_domain_uuid)} onClick={assign}><FormattedMessage id={assignAction === 'transfer' ? 'dids.transfer' : 'dids.assign'} /></Button></DialogActions></Dialog>
    <Dialog open={Boolean(transition)} onClose={() => !busy && setTransition(null)} fullWidth maxWidth="sm"><DialogTitle>{transition ? intl.formatMessage({ id: `dids.${transition.action}Title` }, { number: transition.did.display_number }) : ''}</DialogTitle><DialogContent><Stack spacing={2} sx={{ mt: 1 }}><Alert severity={transition?.action === 'release' ? 'error' : 'warning'}><FormattedMessage id={`dids.${transition?.action || 'suspend'}Warning`} /></Alert><TextField required label={<FormattedMessage id="dids.reason" />} value={transitionReason} onChange={(e) => setTransitionReason(e.target.value)} /></Stack></DialogContent><DialogActions><Button onClick={() => setTransition(null)}><FormattedMessage id="common.cancel" /></Button><Button color={transition?.action === 'release' ? 'error' : 'primary'} variant="contained" disabled={busy || transitionReason.trim().length < 2} onClick={applyTransition}><FormattedMessage id={`dids.${transition?.action || 'suspend'}`} /></Button></DialogActions></Dialog>
    <Dialog open={Boolean(basicRelease)} onClose={() => !busy && setBasicRelease(null)} fullWidth maxWidth="md"><DialogTitle><FormattedMessage id="dids.releaseToSimpleTitle" values={{ number: basicRelease?.did.display_number || '' }} /></DialogTitle><DialogContent><Stack spacing={2} sx={{ mt: 1 }}>
      <Alert severity={basicRelease?.inspection.dedicated_entry ? 'warning' : 'error'}><FormattedMessage id={basicRelease?.inspection.dedicated_entry ? 'dids.releaseToSimpleWarning' : 'dids.advancedEntryUnsafe'} /></Alert>
      {basicRelease?.inspection.entry && <Typography variant="body2"><FormattedMessage id="dids.advancedEntry" />: {basicRelease.inspection.entry.dialplan_name || basicRelease.inspection.entry.dialplan_uuid}</Typography>}
      <FormControl><InputLabel><FormattedMessage id="dids.initialExtensions" /></InputLabel><Select multiple label={<FormattedMessage id="dids.initialExtensions" />} value={basicRelease?.extension_uuids || []} onChange={(e) => setBasicRelease((v) => ({ ...v, extension_uuids: e.target.value }))}>
        {data.extensions.filter((item) => item.customer_uuid === basicRelease?.did.customer_uuid && item.fusion_domain_uuid === basicRelease?.did.fusion_domain_uuid && item.enabled).map((extension) => <MenuItem key={extension.extension_uuid} value={extension.extension_uuid}>{extension.extension} · {extension.effective_caller_id_name || ''}</MenuItem>)}
      </Select></FormControl>
      <TextField required label={<FormattedMessage id="dids.reason" />} value={basicRelease?.reason || ''} onChange={(e) => setBasicRelease((v) => ({ ...v, reason: e.target.value }))} />
      {Boolean(basicRelease?.inspection.related_suggestions?.length) && <Alert severity="info"><FormattedMessage id="dids.relatedAdvancedResources" /><br />{basicRelease.inspection.related_suggestions.map((item) => `${item.dialplan_detail_type}: ${item.dialplan_detail_data}`).join(' · ')}</Alert>}
    </Stack></DialogContent><DialogActions><Button onClick={() => setBasicRelease(null)}><FormattedMessage id="common.cancel" /></Button><Button color="success" variant="contained" disabled={busy || !basicRelease?.inspection.dedicated_entry || basicRelease.extension_uuids.length === 0 || basicRelease.reason.trim().length < 2} onClick={releaseToSimple}><FormattedMessage id="dids.releaseToSimple" /></Button></DialogActions></Dialog>
  </MainCard>;
}
