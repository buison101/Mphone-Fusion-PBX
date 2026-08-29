import { useCallback, useEffect, useState } from 'react';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import MenuItem from '@mui/material/MenuItem';
import Select from '@mui/material/Select';
import Stack from '@mui/material/Stack';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import { FormattedMessage, useIntl } from 'react-intl';
import MainCard from 'components/MainCard';
import ContentState from 'components/states/ContentState';
import useSession from 'hooks/useSession';
import { CUSTOMER_URL } from 'config';

const TYPES = ['quantity_change', 'plan_cycle_change', 'cancel_at_renewal'];
const CAPABILITIES = ['call_forwarding', 'external_forwarding', 'call_history', 'outbound_calling', 'call_statistics',
  'call_recording', 'recording_download', 'speech_to_text', 'ai_summary', 'ai_auto_answer'];

export default function CustomerServices() {
  const intl = useIntl();
  const { session } = useSession();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ change_type: 'quantity_change', requested_quantity: '', requested_plan_uuid: '', requested_billing_cycle: '', reason: '' });
  const load = useCallback(async () => {
    const response = await fetch(`${CUSTOMER_URL}?resource=subscription`, { credentials: 'same-origin' });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(payload.error || 'service_unavailable');
    setData(payload);
  }, []);
  useEffect(() => { load().catch((err) => setError(err.message)).finally(() => setLoading(false)); }, [load]);
  const subscription = data?.subscriptions?.[0];
  const submit = async () => {
    setBusy(true); setError('');
    try {
      const quantityType = form.change_type === 'quantity_change';
      const planType = form.change_type === 'plan_cycle_change';
      const response = await fetch(CUSTOMER_URL, { method: 'POST', credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session?.csrf || '' },
        body: JSON.stringify({ resource: 'subscription_change_submit', subscription_uuid: subscription.subscription_uuid,
          change_type: form.change_type, requested_quantity: quantityType ? Number(form.requested_quantity) : null,
          requested_plan_uuid: planType ? form.requested_plan_uuid || null : null,
          requested_billing_cycle: planType ? form.requested_billing_cycle || null : null, reason: form.reason }) });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable');
      setOpen(false); await load();
    } catch (err) { setError(err.message); } finally { setBusy(false); }
  };
  if (!session?.identity || !session?.workspace?.active) return <ContentState state="forbidden" title={<FormattedMessage id="customer.workspaceRequired" />} />;
  if (loading) return <ContentState loading />;
  return <Stack spacing={2}>
    <Typography variant="h4"><FormattedMessage id="subscription.title" /></Typography>
    {error && <Alert severity="error"><FormattedMessage id={`subscription.error.${error}`} defaultMessage={error} /></Alert>}
    {!subscription ? <Alert severity="info"><FormattedMessage id="subscription.empty" /></Alert> : <MainCard title={subscription.display_name}>
      <Stack spacing={1}><Typography><FormattedMessage id="subscription.plan" />: {subscription.name} ({subscription.code})</Typography>
        <Typography><FormattedMessage id="subscription.quantity" />: {subscription.billable_quantity}</Typography>
        <Typography><FormattedMessage id="subscription.cycle" />: <FormattedMessage id={`subscription.cycle.${subscription.billing_cycle}`} /></Typography>
        <Typography><FormattedMessage id="subscription.period" />: {subscription.period_start} – {subscription.period_end}</Typography>
        <Typography><FormattedMessage id="subscription.total" />: {new Intl.NumberFormat(intl.locale).format(subscription.total_amount)} {subscription.currency}</Typography>
        <Stack direction="row" spacing={1} alignItems="center"><Chip size="small" label={<FormattedMessage id={`subscription.status.${subscription.status}`} />} />
          {data.capabilities?.request_change && <Button variant="outlined" disabled={data.requests?.some((item) => ['submitted', 'imported'].includes(item.status))} onClick={() => setOpen(true)}><FormattedMessage id="subscription.requestChange" /></Button>}</Stack>
      </Stack></MainCard>}
    {data?.entitlement && <MainCard title={<FormattedMessage id="subscription.features" />}><Stack spacing={1.5}>
      <Alert severity={data.entitlement.status === 'active' ? 'info' : 'warning'}><FormattedMessage
        id={data.entitlement.status === 'active' ? 'subscription.featuresActive' : 'subscription.featuresInactive'} /></Alert>
      <Stack direction="row" useFlexGap flexWrap="wrap" gap={1}>{CAPABILITIES.map((key) => <Chip key={key}
        color={data.entitlement.capabilities?.[key] === true ? 'success' : 'default'}
        variant={data.entitlement.capabilities?.[key] === true ? 'filled' : 'outlined'}
        label={<FormattedMessage id={`subscription.capability.${key}`} />} />)}</Stack>
      <Typography variant="caption" color="text.secondary"><FormattedMessage id="subscription.entitlementVersion"
        values={{ generation: data.entitlement.generation, mode: data.entitlement.enforcement_mode }} /></Typography>
    </Stack></MainCard>}
    <MainCard title={<FormattedMessage id="subscription.requestHistory" />}><Stack spacing={1}>
      {(data?.requests || []).map((item) => <Stack key={item.request_uuid} direction="row" justifyContent="space-between"><Typography><FormattedMessage id={`subscription.change.${item.change_type}`} /> · {new Date(item.created_at).toLocaleString(intl.locale)}</Typography><Chip size="small" label={<FormattedMessage id={`subscription.requestStatus.${item.status}`} />}/></Stack>)}
      {!data?.requests?.length && <Typography color="text.secondary"><FormattedMessage id="subscription.requestEmpty" /></Typography>}</Stack></MainCard>
    <Dialog open={open} onClose={() => !busy && setOpen(false)} fullWidth maxWidth="sm"><DialogTitle><FormattedMessage id="subscription.requestChange" /></DialogTitle><DialogContent><Stack spacing={2} sx={{ pt: 1 }}>
      <Alert severity="info"><FormattedMessage id="subscription.reviewHelp" /></Alert>
      <FormControl fullWidth><InputLabel><FormattedMessage id="subscription.changeType" /></InputLabel><Select value={form.change_type} label={intl.formatMessage({ id: 'subscription.changeType' })} onChange={(event) => setForm((value) => ({ ...value, change_type: event.target.value }))}>{TYPES.map((type) => <MenuItem key={type} value={type}><FormattedMessage id={`subscription.change.${type}`} /></MenuItem>)}</Select></FormControl>
      {form.change_type === 'quantity_change' && <TextField type="number" inputProps={{ min: 1 }} required label={intl.formatMessage({ id: 'subscription.requestedQuantity' })} value={form.requested_quantity} onChange={(event) => setForm((value) => ({ ...value, requested_quantity: event.target.value }))} />}
      {form.change_type === 'plan_cycle_change' && <><FormControl fullWidth required><InputLabel><FormattedMessage id="subscription.requestedPlan" /></InputLabel><Select value={form.requested_plan_uuid} label={intl.formatMessage({ id: 'subscription.requestedPlan' })} onChange={(event) => setForm((value) => ({ ...value, requested_plan_uuid: event.target.value }))}>{(data?.plans || []).map((plan) => <MenuItem key={plan.plan_uuid} value={plan.plan_uuid}>{plan.name} · {new Intl.NumberFormat(intl.locale).format(plan.amount)} {plan.currency}</MenuItem>)}</Select></FormControl>
      <FormControl fullWidth required><InputLabel><FormattedMessage id="subscription.requestedCycle" /></InputLabel><Select value={form.requested_billing_cycle} label={intl.formatMessage({ id: 'subscription.requestedCycle' })} onChange={(event) => setForm((value) => ({ ...value, requested_billing_cycle: event.target.value }))}>{['monthly', 'annual'].map((cycle) => <MenuItem key={cycle} value={cycle}><FormattedMessage id={`subscription.cycle.${cycle}`} /></MenuItem>)}</Select></FormControl></>}
      <TextField multiline minRows={3} inputProps={{ maxLength: 1000 }} label={intl.formatMessage({ id: 'subscription.reason' })} value={form.reason} onChange={(event) => setForm((value) => ({ ...value, reason: event.target.value }))} />
    </Stack></DialogContent><DialogActions><Button disabled={busy} onClick={() => setOpen(false)}><FormattedMessage id="users.cancel" /></Button><Button variant="contained" disabled={busy} onClick={submit}><FormattedMessage id="subscription.submit" /></Button></DialogActions></Dialog>
  </Stack>;
}
