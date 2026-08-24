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
  const [editing, setEditing] = useState(null);
  const [detail, setDetail] = useState(null);

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
            customer.customer_code,
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
  const saveCustomer = async () => {
    setBusy(true);
    setError('');
    try {
      await request({
        action: 'update',
        customer_uuid: editing.customer_uuid,
        display_name: editing.display_name,
        customer_type: editing.customer_type
      });
      if (editing.status !== editing.original_status)
        await request({ action: 'status', customer_uuid: editing.customer_uuid, status: editing.status });
      setEditing(null);
      await load();
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
                  <FormattedMessage id="customers.domain" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="customers.owner" />
                </TableCell>
                <TableCell align="right">
                  <FormattedMessage id="customers.users" />
                </TableCell>
                <TableCell align="right">
                  <FormattedMessage id="customers.extensions" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="customers.status" />
                </TableCell>
                <TableCell align="right">
                  <FormattedMessage id="customers.actions" />
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filtered.map((customer) => (
                <TableRow key={customer.customer_uuid}>
                  <TableCell>{customer.display_name}</TableCell>
                  <TableCell>
                    {(customer.tenants || []).map((tenant) => tenant.domain_name || tenant.tenant_key).join(', ') || '—'}
                  </TableCell>
                  <TableCell>{customer.owner_email || '—'}</TableCell>
                  <TableCell align="right">{customer.membership_count}</TableCell>
                  <TableCell align="right">{customer.extension_count}</TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      color={customer.status === 'active' ? 'success' : customer.status === 'suspended' ? 'warning' : 'default'}
                      label={intl.formatMessage({ id: `customers.status.${customer.status}` })}
                    />
                  </TableCell>
                  <TableCell align="right">
                    <Button size="small" disabled={busy} onClick={() => openDetail(customer)}>
                      <FormattedMessage id="customers.view" />
                    </Button>
                    <Button size="small" onClick={() => setEditing({ ...customer, original_status: customer.status })}>
                      <FormattedMessage id="customers.edit" />
                    </Button>
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
      <Dialog open={Boolean(editing)} onClose={() => setEditing(null)} fullWidth maxWidth="sm">
        <DialogTitle>
          <FormattedMessage id="customers.edit" />
        </DialogTitle>
        <DialogContent>
          {editing && (
            <Stack spacing={2} sx={{ pt: 1 }}>
              <TextField
                label={intl.formatMessage({ id: 'customers.name' })}
                value={editing.display_name}
                onChange={(event) => setEditing({ ...editing, display_name: event.target.value })}
              />
              <FormControl>
                <InputLabel>
                  <FormattedMessage id="customers.status" />
                </InputLabel>
                <Select
                  value={editing.status}
                  label={intl.formatMessage({ id: 'customers.status' })}
                  onChange={(event) => setEditing({ ...editing, status: event.target.value })}
                >
                  {customerStatuses.map((status) => (
                    <MenuItem key={status} value={status}>
                      {intl.formatMessage({ id: `customers.status.${status}` })}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              {['suspended', 'closed'].includes(editing.status) && editing.status !== editing.original_status && (
                <Alert severity="warning">
                  <FormattedMessage id="customers.statusWarning" />
                </Alert>
              )}
            </Stack>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditing(null)}>
            <FormattedMessage id="customers.cancel" />
          </Button>
          <Button variant="contained" disabled={busy || editing?.display_name.trim().length < 2} onClick={saveCustomer}>
            <FormattedMessage id="customers.save" />
          </Button>
        </DialogActions>
      </Dialog>
      <Dialog open={Boolean(detail)} onClose={() => setDetail(null)} fullWidth maxWidth="md">
        <DialogTitle>{detail?.customer?.display_name}</DialogTitle>
        <DialogContent>
          {detail && (
            <Stack spacing={2}>
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
              <Typography variant="subtitle1">
                <FormattedMessage id="customers.detail.extensions" />
              </Typography>
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
    </MainCard>
  );
}
