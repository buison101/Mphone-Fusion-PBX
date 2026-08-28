import { useCallback, useEffect, useMemo, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
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
import { CUSTOMERS_URL } from 'config';

const customerTypes = ['individual', 'organization'];
const customerStatuses = ['pending', 'active', 'suspended', 'closed'];

export default function Customers() {
  const intl = useIntl();
  const { session } = useSession();
  const [data, setData] = useState({ customers: [], available_tenants: [] });
  const [query, setQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [createOpen, setCreateOpen] = useState(false);
  const [form, setForm] = useState({ display_name: '', customer_type: 'organization', tenant_uuid: '' });
  const [detail, setDetail] = useState(null);
  const [extensionOpen, setExtensionOpen] = useState(false);
  const [profileReview, setProfileReview] = useState(null);
  const [reviewNote, setReviewNote] = useState('');

  const request = useCallback(
    async (body) => {
      const response = await fetch(CUSTOMERS_URL, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session?.csrf || '' },
        body: JSON.stringify(body)
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable');
      return payload;
    },
    [session?.csrf]
  );

  const load = useCallback(async () => {
    try {
      const response = await fetch(`${CUSTOMERS_URL}?action=list`, { credentials: 'same-origin' });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable');
      setData(payload);
      setError('');
    } catch (err) {
      setError(err.message);
    }
  }, []);
  useEffect(() => {
    if (session?.user_management?.superadmin) load();
  }, [load, session?.user_management?.superadmin]);

  const filtered = useMemo(
    () =>
      data.customers.filter((customer) => {
        const needle = query.trim().toLowerCase();
        const matchesText =
          !needle ||
          [
            customer.display_name,
            customer.legal_name,
            customer.contact_email,
            customer.phone,
            customer.owner_email,
            ...(customer.tenants || []).map((tenant) => tenant.domain_name)
          ].some((value) =>
            String(value || '')
              .toLowerCase()
              .includes(needle)
          );
        const matchesStatus = statusFilter === 'all' ? customer.status !== 'closed' : customer.status === statusFilter;
        return matchesText && matchesStatus;
      }),
    [data.customers, query, statusFilter]
  );

  const createCustomer = async () => {
    setBusy(true);
    setError('');
    try {
      await request({ action: 'create', ...form });
      setCreateOpen(false);
      setForm({ display_name: '', customer_type: 'organization', tenant_uuid: data.available_tenants[0]?.tenant_uuid || '' });
      await load();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };
  const updateCustomerStatus = async (customerUuid, status) => {
    setBusy(true);
    setError('');
    try {
      await request({ action: 'status', customer_uuid: customerUuid, status });
      await load();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };
  const retrySync = async (customerUuid) => {
    setBusy(true);
    setError('');
    try {
      await request({ action: 'sync_retry', customer_uuid: customerUuid });
      await load();
      if (detail?.customer?.customer_uuid === customerUuid) await openDetail({ customer_uuid: customerUuid });
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };
  const openDetail = async (customer) => {
    setBusy(true);
    setError('');
    try {
      setDetail(await request({ action: 'detail', customer_uuid: customer.customer_uuid }));
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };
  const assignExtension = async (extension) => {
    if (!detail?.customer?.customer_uuid) return;
    const transferring = Boolean(extension.owner_customer_uuid && extension.owner_customer_uuid !== detail.customer.customer_uuid);
    if (
      transferring &&
      !window.confirm(
        intl.formatMessage(
          { id: 'customers.extensions.transferConfirm' },
          { extension: extension.extension, owner: extension.owner_name, target: detail.customer.display_name }
        )
      )
    )
      return;
    setBusy(true);
    setError('');
    try {
      await request({
        action: 'extension_transfer',
        customer_uuid: detail.customer.customer_uuid,
        extension_uuid: extension.extension_uuid,
        confirm_transfer: transferring,
        source_customer_uuid: extension.owner_customer_uuid
      });
      await Promise.all([load(), openDetail({ customer_uuid: detail.customer.customer_uuid })]);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };
  const decideProfileChange = async (decision) => {
    if (!profileReview || !detail?.customer?.customer_uuid) return;
    setBusy(true);
    setError('');
    try {
      await request({
        action: decision === 'approve' ? 'profile_change_approve' : 'profile_change_reject',
        request_uuid: profileReview.request_uuid,
        review_note: reviewNote
      });
      const customerUuid = detail.customer.customer_uuid;
      setProfileReview(null);
      setReviewNote('');
      await openDetail({ customer_uuid: customerUuid });
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };
  const retryProfileChange = async (requestUuid) => {
    if (!detail?.customer?.customer_uuid) return;
    setBusy(true); setError('');
    try {
      await request({ action: 'profile_change_retry', request_uuid: requestUuid });
      await openDetail({ customer_uuid: detail.customer.customer_uuid });
    } catch (err) { setError(err.message); } finally { setBusy(false); }
  };

  if (!session?.user_management?.superadmin) return <ContentState title={<FormattedMessage id="customers.forbidden" />} />;
  return (
    <MainCard
      title={<FormattedMessage id="customers.title" />}
      secondary={
        <Button
          variant="contained"
          onClick={() => {
            setForm({ display_name: '', customer_type: 'organization', tenant_uuid: data.available_tenants[0]?.tenant_uuid || '' });
            setCreateOpen(true);
          }}
        >
          <FormattedMessage id="customers.create" />
        </Button>
      }
    >
      <Stack spacing={2}>
        {error && (
          <Alert severity="error">
            <FormattedMessage id={`customers.error.${error}`} defaultMessage={intl.formatMessage({ id: 'customers.error.generic' })} />
          </Alert>
        )}
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1}>
          <TextField
            size="small"
            label={intl.formatMessage({ id: 'customers.search' })}
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            sx={{ minWidth: 280 }}
          />
          <FormControl size="small" sx={{ minWidth: 180 }}>
            <InputLabel>
              <FormattedMessage id="customers.status" />
            </InputLabel>
            <Select
              value={statusFilter}
              label={intl.formatMessage({ id: 'customers.status' })}
              onChange={(event) => setStatusFilter(event.target.value)}
            >
              <MenuItem value="all">
                <FormattedMessage id="customers.status.all" />
              </MenuItem>
              {customerStatuses.map((status) => (
                <MenuItem key={status} value={status}>
                  {intl.formatMessage({ id: `customers.status.${status}` })}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Stack>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>
                  <FormattedMessage id="customers.name" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="customers.contactEmail" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="customers.status" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="customers.phone" />
                </TableCell>
                <TableCell align="right">
                  <FormattedMessage id="customers.users" />
                </TableCell>
                <TableCell align="right">
                  <FormattedMessage id="customers.extensions" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="customers.plan" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="customers.subscriptionStatus" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="customers.sync" />
                </TableCell>
                <TableCell align="right">
                  <FormattedMessage id="customers.actions" />
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filtered.map((customer) => (
                <TableRow key={customer.customer_uuid}>
                  <TableCell>
                    <Typography>{customer.display_name}</Typography>
                  </TableCell>
                  <TableCell>{customer.contact_email || '—'}</TableCell>
                  <TableCell>
                    <FormControl size="small" sx={{ minWidth: 132 }}>
                      <Select
                        value={customer.status}
                        disabled={busy}
                        inputProps={{ 'aria-label': intl.formatMessage({ id: 'customers.status' }) }}
                        onChange={(event) => updateCustomerStatus(customer.customer_uuid, event.target.value)}
                      >
                        {customerStatuses.map((status) => (
                          <MenuItem key={status} value={status}>
                            {intl.formatMessage({ id: `customers.status.${status}` })}
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </TableCell>
                  <TableCell>{customer.phone || '—'}</TableCell>
                  <TableCell align="right">{customer.membership_count}</TableCell>
                  <TableCell align="right">{customer.extension_count}</TableCell>
                  <TableCell>{customer.subscription_name || '—'}</TableCell>
                  <TableCell>
                    {customer.subscription_status ? (
                      <Chip size="small" label={intl.formatMessage({ id: `customers.subscription.${customer.subscription_status}` })} />
                    ) : (
                      '—'
                    )}
                  </TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      color={customer.sync_status === 'linked' ? 'success' : customer.sync_status === 'error' ? 'error' : 'warning'}
                      label={intl.formatMessage({ id: `customers.sync.${customer.sync_status}` })}
                    />
                  </TableCell>
                  <TableCell align="right">
                    <Button size="small" disabled={busy} onClick={() => openDetail(customer)}>
                      <FormattedMessage id="customers.view" />
                    </Button>
                    {customer.odoo_url && (
                      <Button size="small" component="a" href={customer.odoo_url} target="_blank" rel="noreferrer">
                        <FormattedMessage id="customers.openOdoo" />
                      </Button>
                    )}
                    {['error', 'unlinked'].includes(customer.sync_status) && (
                      <Button size="small" disabled={busy} onClick={() => retrySync(customer.customer_uuid)}>
                        <FormattedMessage id="customers.retrySync" />
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
        {filtered.length === 0 && (
          <Typography color="text.secondary">
            <FormattedMessage id="customers.empty" />
          </Typography>
        )}
      </Stack>
      <Dialog open={createOpen} onClose={() => setCreateOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>
          <FormattedMessage id="customers.create" />
        </DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ pt: 1 }}>
            <TextField
              label={intl.formatMessage({ id: 'customers.name' })}
              value={form.display_name}
              onChange={(event) => setForm({ ...form, display_name: event.target.value })}
            />
            <FormControl>
              <InputLabel>
                <FormattedMessage id="customers.type" />
              </InputLabel>
              <Select
                value={form.customer_type}
                label={intl.formatMessage({ id: 'customers.type' })}
                onChange={(event) => setForm({ ...form, customer_type: event.target.value })}
              >
                {customerTypes.map((type) => (
                  <MenuItem key={type} value={type}>
                    {intl.formatMessage({ id: `customers.type.${type}` })}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <FormControl>
              <InputLabel>
                <FormattedMessage id="customers.tenant" />
              </InputLabel>
              <Select
                value={form.tenant_uuid}
                label={intl.formatMessage({ id: 'customers.tenant' })}
                onChange={(event) => setForm({ ...form, tenant_uuid: event.target.value })}
              >
                {data.available_tenants.map((tenant) => (
                  <MenuItem key={tenant.tenant_uuid} value={tenant.tenant_uuid}>
                    {tenant.domain_name || tenant.tenant_key}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <Alert severity="info">
              <FormattedMessage id="customers.createHelp" />
            </Alert>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateOpen(false)}>
            <FormattedMessage id="customers.cancel" />
          </Button>
          <Button variant="contained" disabled={busy || form.display_name.trim().length < 2 || !form.tenant_uuid} onClick={createCustomer}>
            <FormattedMessage id="customers.create" />
          </Button>
        </DialogActions>
      </Dialog>
      <Dialog open={Boolean(detail)} onClose={() => setDetail(null)} fullWidth maxWidth="md">
        <DialogTitle>{detail?.customer?.display_name}</DialogTitle>
        <DialogContent>
          {detail && (
            <Stack spacing={2}>
              <Typography variant="subtitle1">
                <FormattedMessage id="customers.detail.profile" />
              </Typography>
              <Stack spacing={0.5}>
                <Typography>
                  <FormattedMessage id="customers.legalName" />: {detail.customer.legal_name || detail.customer.display_name || '—'}
                </Typography>
                <Typography>
                  <FormattedMessage id="customers.contactEmail" />: {detail.customer.contact_email || '—'}
                </Typography>
                <Typography>
                  <FormattedMessage id="customers.phone" />: {detail.customer.phone || '—'}
                </Typography>
                <Typography>
                  <FormattedMessage id="customers.address" />:{' '}
                  {[
                    detail.customer.street,
                    detail.customer.street2,
                    detail.customer.city,
                    detail.customer.postal_code,
                    detail.customer.country_code
                  ]
                    .filter(Boolean)
                    .join(', ') || '—'}
                </Typography>
                <Typography>
                  <FormattedMessage id="customers.taxId" />: {detail.customer.tax_id || '—'}
                </Typography>
                <Typography>
                  <FormattedMessage id="customers.website" />: {detail.customer.website || '—'}
                </Typography>
              </Stack>
              <Typography variant="subtitle1">
                <FormattedMessage id="customers.detail.subscription" />
              </Typography>
              {(detail.subscriptions || []).length ? (
                detail.subscriptions.map((subscription) => (
                  <Stack key={subscription.subscription_uuid} spacing={0.5}>
                    <Typography>
                      {subscription.display_name} · {intl.formatMessage({ id: `customers.subscription.${subscription.status}` })}
                    </Typography>
                    <Typography color="text.secondary">
                      {subscription.billable_quantity} × {Number(subscription.unit_monthly_price).toLocaleString()} {subscription.currency}{' '}
                      / {intl.formatMessage({ id: `customers.cycle.${subscription.billing_cycle}` })}
                    </Typography>
                    <Typography color="text.secondary">
                      {subscription.period_start} – {subscription.period_end} · {Number(subscription.total_amount).toLocaleString()}{' '}
                      {subscription.currency}
                    </Typography>
                  </Stack>
                ))
              ) : (
                <Typography color="text.secondary">
                  <FormattedMessage id="customers.subscription.none" />
                </Typography>
              )}
              <Stack direction="row" spacing={1} alignItems="center" useFlexGap flexWrap="wrap">
                <Chip
                  size="small"
                  color={
                    detail.customer.sync_status === 'linked' ? 'success' : detail.customer.sync_status === 'error' ? 'error' : 'warning'
                  }
                  label={intl.formatMessage({ id: `customers.sync.${detail.customer.sync_status}` })}
                />
                {detail.customer.last_synced_at && (
                  <Typography variant="body2" color="text.secondary">
                    <FormattedMessage id="customers.lastSynced" />: {new Date(detail.customer.last_synced_at).toLocaleString()}
                  </Typography>
                )}
                {detail.customer.odoo_url && (
                  <Button size="small" component="a" href={detail.customer.odoo_url} target="_blank" rel="noreferrer">
                    <FormattedMessage id="customers.openOdoo" />
                  </Button>
                )}
                {['error', 'unlinked'].includes(detail.customer.sync_status) && (
                  <Button size="small" disabled={busy} onClick={() => retrySync(detail.customer.customer_uuid)}>
                    <FormattedMessage id="customers.retrySync" />
                  </Button>
                )}
              </Stack>
              <Typography variant="subtitle1">
                <FormattedMessage id="customers.detail.users" />
              </Typography>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>
                      <FormattedMessage id="customers.email" />
                    </TableCell>
                    <TableCell>
                      <FormattedMessage id="customers.user" />
                    </TableCell>
                    <TableCell>
                      <FormattedMessage id="customers.role" />
                    </TableCell>
                    <TableCell>
                      <FormattedMessage id="customers.status" />
                    </TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {detail.memberships.map((member) => (
                    <TableRow key={member.membership_uuid}>
                      <TableCell>{member.primary_email}</TableCell>
                      <TableCell>{member.username || '—'}</TableCell>
                      <TableCell>{member.role}</TableCell>
                      <TableCell>{member.status}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              <Stack direction="row" justifyContent="space-between" alignItems="center">
                <Typography variant="subtitle1">
                  <FormattedMessage id="customers.detail.extensions" />
                </Typography>
                <Button size="small" variant="outlined" onClick={() => setExtensionOpen(true)}>
                  <FormattedMessage id="customers.extensions.manage" />
                </Button>
              </Stack>
              <Stack direction="row" spacing={1} useFlexGap flexWrap="wrap">
                {detail.extensions.map((extension) => (
                  <Chip
                    key={extension.extension_uuid}
                    label={`${extension.extension || '—'}${extension.display_name ? ` — ${extension.display_name}` : ''}`}
                  />
                ))}
                {detail.extensions.length === 0 && <Typography color="text.secondary">—</Typography>}
              </Stack>
              <Typography variant="subtitle1">
                <FormattedMessage id="customers.profileChanges" />
              </Typography>
              {(detail.profile_change_requests || []).map((item) => (
                <Stack key={item.request_uuid} direction={{ xs: 'column', sm: 'row' }} spacing={1}
                  justifyContent="space-between" alignItems={{ sm: 'center' }}>
                  <Stack>
                    <Typography>{item.requested_by_email} · {new Date(item.submitted_at).toLocaleString()}</Typography>
                    <Typography variant="caption" color="text.secondary">{(item.changed_fields || []).join(', ')}</Typography>
                    {item.review_note && <Typography variant="caption" color="text.secondary">{item.review_note}</Typography>}
                  </Stack>
                  <Stack direction="row" spacing={1} alignItems="center">
                    <Chip size="small" label={intl.formatMessage({ id: `customer.changeStatus.${item.status}` })} />
                    {['submitted', 'under_review'].includes(item.status) && (
                      <Button size="small" onClick={() => { setProfileReview(item); setReviewNote(''); }}>
                        <FormattedMessage id="customers.review" />
                      </Button>
                    )}
                    {item.status === 'failed' && (
                      <Button size="small" disabled={busy} onClick={() => retryProfileChange(item.request_uuid)}>
                        <FormattedMessage id="customers.retrySync" />
                      </Button>
                    )}
                  </Stack>
                </Stack>
              ))}
              {!detail.profile_change_requests?.length && <Typography color="text.secondary">—</Typography>}
              <Typography variant="subtitle1">
                <FormattedMessage id="customers.detail.audit" />
              </Typography>
              {detail.events.slice(0, 20).map((event) => (
                <Typography key={event.event_uuid} variant="body2">
                  {new Date(event.created_at).toLocaleString()} — {event.action} — {event.result}
                </Typography>
              ))}
              {detail.events.length === 0 && <Typography color="text.secondary">—</Typography>}
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetail(null)}>
            <FormattedMessage id="customers.close" />
          </Button>
        </DialogActions>
      </Dialog>
      <Dialog open={Boolean(profileReview)} onClose={() => !busy && setProfileReview(null)} fullWidth maxWidth="sm">
        <DialogTitle><FormattedMessage id="customers.reviewProfileChange" /></DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ pt: 1 }}>
            {(profileReview?.changed_fields || []).map((field) => (
              <Stack key={field}>
                <Typography variant="caption" color="text.secondary"><FormattedMessage id={`customer.field.${field}`} /></Typography>
                <Typography>{String(profileReview?.old_values?.[field] || '—')} → {String(profileReview?.new_values?.[field] || '—')}</Typography>
              </Stack>
            ))}
            <TextField multiline minRows={3} value={reviewNote} onChange={(event) => setReviewNote(event.target.value)}
              label={intl.formatMessage({ id: 'customers.reviewNote' })} inputProps={{ maxLength: 1000 }} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button disabled={busy} onClick={() => setProfileReview(null)}><FormattedMessage id="customers.cancel" /></Button>
          <Button color="error" disabled={busy || reviewNote.trim().length < 2} onClick={() => decideProfileChange('reject')}>
            <FormattedMessage id="customers.reject" />
          </Button>
          <Button variant="contained" disabled={busy} onClick={() => decideProfileChange('approve')}>
            <FormattedMessage id="customers.approve" />
          </Button>
        </DialogActions>
      </Dialog>
      <Dialog open={extensionOpen} onClose={() => !busy && setExtensionOpen(false)} fullWidth maxWidth="md">
        <DialogTitle>
          <FormattedMessage id="customers.extensions.title" values={{ customer: detail?.customer?.display_name || '' }} />
        </DialogTitle>
        <DialogContent>
          <Alert severity="info" sx={{ mb: 2 }}>
            <FormattedMessage id="customers.extensions.help" />
          </Alert>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>
                  <FormattedMessage id="customers.extensions.extension" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="customers.extensions.currentOwner" />
                </TableCell>
                <TableCell align="right">
                  <FormattedMessage id="customers.actions" />
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(detail?.extension_candidates || []).map((extension) => {
                const current = extension.owner_customer_uuid === detail?.customer?.customer_uuid;
                return (
                  <TableRow key={extension.extension_uuid}>
                    <TableCell>
                      {extension.extension}
                      {extension.display_name ? ` · ${extension.display_name}` : ''}
                    </TableCell>
                    <TableCell>{extension.owner_name || <FormattedMessage id="customers.extensions.unassigned" />}</TableCell>
                    <TableCell align="right">
                      <Button size="small" disabled={busy || current} onClick={() => assignExtension(extension)}>
                        <FormattedMessage
                          id={
                            current
                              ? 'customers.extensions.current'
                              : extension.owner_customer_uuid
                                ? 'customers.extensions.transfer'
                                : 'customers.extensions.assign'
                          }
                        />
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
          {(detail?.extension_candidates || []).length === 0 && (
            <Typography color="text.secondary" sx={{ mt: 2 }}>
              <FormattedMessage id="customers.extensions.none" />
            </Typography>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setExtensionOpen(false)} disabled={busy}>
            <FormattedMessage id="customers.close" />
          </Button>
        </DialogActions>
      </Dialog>
    </MainCard>
  );
}
