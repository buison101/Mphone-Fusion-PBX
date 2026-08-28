import { useCallback, useEffect, useState } from 'react';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import Grid from '@mui/material/Grid';
import Stack from '@mui/material/Stack';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import { FormattedMessage, useIntl } from 'react-intl';

import MainCard from 'components/MainCard';
import ContentState from 'components/states/ContentState';
import useSession from 'hooks/useSession';
import { CUSTOMER_URL } from 'config';

const legalFields = ['legal_name', 'contact_email', 'phone', 'tax_id', 'website', 'street', 'street2', 'city', 'postal_code', 'country_code'];

export default function CustomerProfile() {
  const intl = useIntl();
  const { session } = useSession();
  const [data, setData] = useState(null);
  const [form, setForm] = useState({ display_name: '', operational_contact_email: '', operational_contact_phone: '' });
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [saved, setSaved] = useState('');
  const [legalOpen, setLegalOpen] = useState(false);
  const [legalForm, setLegalForm] = useState({});

  const load = useCallback(async () => {
    setError('');
    const response = await fetch(`${CUSTOMER_URL}?resource=profile`, { credentials: 'same-origin' });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(payload.error || 'service_unavailable');
    const customer = payload.customer || {};
    setData(payload);
    setForm({ display_name: customer.display_name || '', operational_contact_email: customer.operational_contact_email || '',
      operational_contact_phone: customer.operational_contact_phone || '' });
  }, []);

  useEffect(() => {
    load().catch((err) => setError(err.message)).finally(() => setLoading(false));
  }, [load]);

  const save = async () => {
    setBusy(true); setError(''); setSaved('');
    try {
      const response = await fetch(CUSTOMER_URL, {
        method: 'POST', credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session?.csrf || '' },
        body: JSON.stringify({ resource: 'profile_update', ...form, profile_version: data?.customer?.profile_version })
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable');
      await load(); setSaved(payload.unchanged ? 'unchanged' : 'pending');
    } catch (err) {
      setError(err.message);
      if (err.message === 'profile_conflict') await load().catch(() => undefined);
    } finally { setBusy(false); }
  };

  const submitLegalChange = async () => {
    setBusy(true); setError('');
    try {
      const response = await fetch(CUSTOMER_URL, { method: 'POST', credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session?.csrf || '' },
        body: JSON.stringify({ resource: 'profile_change_submit', legal_profile: legalForm }) });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable');
      setLegalOpen(false); await load();
    } catch (err) { setError(err.message); } finally { setBusy(false); }
  };

  const cancelLegalChange = async (requestUuid) => {
    setBusy(true); setError('');
    try {
      const response = await fetch(CUSTOMER_URL, { method: 'POST', credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session?.csrf || '' },
        body: JSON.stringify({ resource: 'profile_change_cancel', request_uuid: requestUuid }) });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable');
      await load();
    } catch (err) { setError(err.message); } finally { setBusy(false); }
  };

  if (loading) return <ContentState loading />;
  if (!data) return <Alert severity="error"><FormattedMessage id="customer.loadError" /></Alert>;
  const customer = data.customer || {};
  const editable = data.capabilities?.edit_operational_profile === true;
  return <Stack spacing={2}>
    <Typography variant="h4"><FormattedMessage id="customer.profileTitle" /></Typography>
    {error && <Alert severity="error"><FormattedMessage id={`customer.error.${error}`} defaultMessage={intl.formatMessage({ id: 'customer.loadError' })} /></Alert>}
    {saved && <Alert severity="success"><FormattedMessage id={saved === 'unchanged' ? 'customer.profileUnchanged' : 'customer.profileSaved'} /></Alert>}
    {customer.operational_sync_status && <Alert severity={['failed', 'dead_letter'].includes(customer.operational_sync_status) ? 'error' : 'info'}>
      <FormattedMessage id={`customer.sync.${customer.operational_sync_status}`} defaultMessage={customer.operational_sync_status} />
    </Alert>}
    <MainCard title={<FormattedMessage id="customer.operationalTitle" />}>
      <Stack spacing={2}>
        <Typography color="text.secondary"><FormattedMessage id="customer.operationalHelp" /></Typography>
        <Grid container spacing={2}>
          <Grid size={{ xs: 12, md: 6 }}><TextField fullWidth required disabled={!editable || busy}
            label={intl.formatMessage({ id: 'customer.field.display_name' })} value={form.display_name}
            inputProps={{ maxLength: 120 }} onChange={(event) => setForm((value) => ({ ...value, display_name: event.target.value }))} /></Grid>
          <Grid size={{ xs: 12, md: 6 }}><TextField fullWidth type="email" disabled={!editable || busy}
            label={intl.formatMessage({ id: 'customer.field.operational_contact_email' })} value={form.operational_contact_email}
            inputProps={{ maxLength: 254 }} onChange={(event) => setForm((value) => ({ ...value, operational_contact_email: event.target.value }))} /></Grid>
          <Grid size={{ xs: 12, md: 6 }}><TextField fullWidth type="tel" disabled={!editable || busy}
            label={intl.formatMessage({ id: 'customer.field.operational_contact_phone' })} value={form.operational_contact_phone}
            inputProps={{ maxLength: 32 }} onChange={(event) => setForm((value) => ({ ...value, operational_contact_phone: event.target.value }))} /></Grid>
        </Grid>
        {editable ? <Stack direction="row" justifyContent="flex-end"><Button variant="contained"
          disabled={busy || form.display_name.trim().length < 2} onClick={save}><FormattedMessage id="customer.saveOperational" /></Button></Stack>
          : <Alert severity="info"><FormattedMessage id="customer.ownerOnly" /></Alert>}
      </Stack>
    </MainCard>
    <MainCard title={<FormattedMessage id="customer.legalTitle" />}>
      <Alert severity="info" sx={{ mb: 2 }}><FormattedMessage id="customer.profileReadOnly" values={{ source: data.source || 'Odoo' }} /></Alert>
      <Grid container spacing={2}>
        {legalFields.map((field) => <Grid key={field} size={{ xs: 12, sm: 6 }}>
          <Typography variant="caption" color="text.secondary"><FormattedMessage id={`customer.field.${field}`} /></Typography>
          <Typography>{customer[field] || '—'}</Typography>
        </Grid>)}
      </Grid>
      {data.capabilities?.request_legal_change && <Stack direction="row" justifyContent="flex-end" sx={{ mt: 2 }}>
        <Button variant="outlined" disabled={busy || data.profile_change_requests?.some((item) => ['submitted', 'under_review', 'approved', 'syncing'].includes(item.status))}
          onClick={() => { setLegalForm(Object.fromEntries(legalFields.filter((field) => field !== 'website').map((field) => [field, customer[field] || '']))); setLegalOpen(true); }}>
          <FormattedMessage id="customer.requestLegalChange" />
        </Button>
      </Stack>}
    </MainCard>
    <MainCard title={<FormattedMessage id="customer.changeHistory" />}>
      <Stack spacing={1.5}>
        {(data.profile_change_requests || []).map((item) => <Stack key={item.request_uuid} direction={{ xs: 'column', sm: 'row' }}
          spacing={1} alignItems={{ sm: 'center' }} justifyContent="space-between">
          <Stack><Typography>{new Date(item.submitted_at).toLocaleString(intl.locale)}</Typography>
            <Typography variant="caption" color="text.secondary">{(item.changed_fields || []).map((field) => intl.formatMessage({ id: `customer.field.${field}` })).join(', ')}</Typography>
            {item.review_note && <Typography variant="caption" color="text.secondary">{item.review_note}</Typography>}
          </Stack>
          <Stack direction="row" spacing={1} alignItems="center"><Chip size="small" label={intl.formatMessage({ id: `customer.changeStatus.${item.status}` })} />
            {item.status === 'submitted' && data.capabilities?.request_legal_change && <Button size="small" disabled={busy}
              onClick={() => cancelLegalChange(item.request_uuid)}><FormattedMessage id="customer.cancelRequest" /></Button>}
          </Stack>
        </Stack>)}
        {!data.profile_change_requests?.length && <Typography color="text.secondary"><FormattedMessage id="customer.changeHistoryEmpty" /></Typography>}
      </Stack>
    </MainCard>
    <Dialog open={legalOpen} onClose={() => !busy && setLegalOpen(false)} fullWidth maxWidth="md">
      <DialogTitle><FormattedMessage id="customer.requestLegalChange" /></DialogTitle>
      <DialogContent><Stack spacing={2} sx={{ pt: 1 }}>
        <Alert severity="warning"><FormattedMessage id="customer.legalReviewHelp" /></Alert>
        <Grid container spacing={2}>{legalFields.filter((field) => field !== 'website').map((field) => <Grid key={field} size={{ xs: 12, sm: 6 }}>
          <TextField fullWidth required={field === 'legal_name'} disabled={busy} value={legalForm[field] || ''}
            label={intl.formatMessage({ id: `customer.field.${field}` })}
            onChange={(event) => setLegalForm((value) => ({ ...value, [field]: event.target.value }))} />
        </Grid>)}</Grid>
      </Stack></DialogContent>
      <DialogActions><Button disabled={busy} onClick={() => setLegalOpen(false)}><FormattedMessage id="users.cancel" /></Button>
        <Button variant="contained" disabled={busy || String(legalForm.legal_name || '').trim().length < 2}
          onClick={submitLegalChange}><FormattedMessage id="customer.submitRequest" /></Button></DialogActions>
    </Dialog>
  </Stack>;
}
