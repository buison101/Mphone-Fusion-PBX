import { useCallback, useEffect, useMemo, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Checkbox from '@mui/material/Checkbox';
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
import { USERS_URL } from 'config';

const roles = ['customer_admin', 'member', 'billing_admin'];

export default function Users() {
  const intl = useIntl();
  const { session } = useSession();
  const [customers, setCustomers] = useState([]);
  const [customerUuid, setCustomerUuid] = useState(session?.customer?.customer_uuid || '');
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [inviteOpen, setInviteOpen] = useState(false);
  const [email, setEmail] = useState('');
  const [inviteRole, setInviteRole] = useState('member');
  const [savingId, setSavingId] = useState('');
  const [mergeOpen, setMergeOpen] = useState(false);
  const [mergeTarget, setMergeTarget] = useState('');
  const [mergePreview, setMergePreview] = useState(null);
  const [mergeConfirmation, setMergeConfirmation] = useState('');
  const [selectedMemberships, setSelectedMemberships] = useState([]);

  const request = useCallback(
    async (body) => {
      const response = await fetch(USERS_URL, {
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
    setError('');
    try {
      const suffix = session?.identity && customerUuid ? `&customer_uuid=${encodeURIComponent(customerUuid)}` : '';
      const response = await fetch(`${USERS_URL}?action=list${suffix}`, {
        credentials: 'same-origin'
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable');
      setData(payload);
    } catch (err) {
      setError(err.message);
    }
  }, [customerUuid, session?.identity]);

  useEffect(() => {
    if (session?.identity) return;
    fetch(`${USERS_URL}?action=customers`, { credentials: 'same-origin' })
      .then((response) => (response.ok ? response.json() : Promise.reject(new Error('service_unavailable'))))
      .then((payload) => {
        setCustomers(payload.customers || []);
        setCustomerUuid((value) => value || payload.customers?.[0]?.customer_uuid || '');
      })
      .catch((err) => setError(err.message));
  }, [session?.identity]);
  useEffect(() => {
    load();
  }, [load]);

  const assignments = useMemo(() => {
    const extensionMap = new Map((data?.extensions || []).map((item) => [item.extension_uuid, item.extension]));
    const map = new Map();
    (data?.assignments || []).forEach((item) => {
      const values = map.get(item.identity_uuid) || [];
      const extension = extensionMap.get(item.extension_uuid);
      if (extension && !values.includes(extension)) values.push(extension);
      map.set(item.identity_uuid, values);
    });
    return map;
  }, [data]);

  const submitInvite = async () => {
    setBusy(true);
    setError('');
    try {
      await request({ action: 'invite', customer_uuid: customerUuid, email, role: inviteRole });
      setInviteOpen(false);
      setEmail('');
      await load();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  const saveMember = async (member, changes) => {
    setSavingId(member.membership_uuid);
    setError('');
    try {
      await request({
        action: 'update',
        customer_uuid: member.customer_uuid || customerUuid,
        identity_uuid: member.identity_uuid,
        role: changes.role || member.role,
        status: changes.status || member.status
      });
      await load();
    } catch (err) {
      setError(err.message);
    } finally {
      setSavingId('');
    }
  };
  const resend = async (member) => {
    setSavingId(member.membership_uuid);
    setError('');
    try {
      await request({
        action: 'resend',
        customer_uuid: member.customer_uuid || customerUuid,
        identity_uuid: member.identity_uuid
      });
      await load();
    } catch (err) {
      setError(err.message);
    } finally {
      setSavingId('');
    }
  };
  const previewMerge = async () => {
    setBusy(true);
    setError('');
    try {
      const selectedRows = (data?.memberships || []).filter((member) => selectedMemberships.includes(member.membership_uuid));
      const sourceCustomerUuids = [...new Set(selectedRows.map((member) => member.customer_uuid))];
      const payload = await request({
        action: 'merge_preview',
        target_customer_uuid: mergeTarget,
        source_customer_uuids: sourceCustomerUuids,
        selected_identity_uuids: selectedRows.map((member) => member.identity_uuid)
      });
      setMergePreview(payload);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };
  const executeMerge = async () => {
    setBusy(true);
    setError('');
    try {
      await request({ action: 'merge_execute', operation_uuid: mergePreview.operation_uuid });
      setMergeOpen(false);
      setMergePreview(null);
      setSelectedMemberships([]);
      setMergeConfirmation('');
      await load();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  };

  if (!session?.user_management?.allowed) return <ContentState title={<FormattedMessage id="users.forbidden" />} />;
  return (
    <MainCard
      title={<FormattedMessage id="users.title" />}
      secondary={
        <Stack direction="row" spacing={1}>
          {session?.user_management?.superadmin && selectedMemberships.length > 0 && (
            <Button
              color="warning"
              variant="outlined"
              onClick={() => {
                const selectedCustomerUuids = new Set(
                  (data?.memberships || [])
                    .filter((member) => selectedMemberships.includes(member.membership_uuid))
                    .map((member) => member.customer_uuid)
                );
                setMergeTarget(customers.find((customer) => !selectedCustomerUuids.has(customer.customer_uuid))?.customer_uuid || '');
                setMergePreview(null);
                setMergeConfirmation('');
                setMergeOpen(true);
              }}
            >
              <FormattedMessage id="users.transfer.action" />
            </Button>
          )}
          <Button variant="contained" onClick={() => setInviteOpen(true)} disabled={!customerUuid}>
            <FormattedMessage id="users.invite" />
          </Button>
        </Stack>
      }
    >
      <Stack spacing={2}>
        {error && (
          <Alert severity="error">
            <FormattedMessage id={`users.error.${error}`} defaultMessage={intl.formatMessage({ id: 'users.error.generic' })} />
          </Alert>
        )}
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                {session?.user_management?.superadmin && (
                  <TableCell>
                    <Stack direction="row" alignItems="center" spacing={0.5}>
                      <Checkbox
                        indeterminate={selectedMemberships.length > 0 && selectedMemberships.length < (data?.memberships || []).length}
                        checked={(data?.memberships || []).length > 0 && selectedMemberships.length === (data?.memberships || []).length}
                        onChange={() =>
                          setSelectedMemberships((current) =>
                            current.length > 0 ? [] : (data?.memberships || []).map((member) => member.membership_uuid)
                          )
                        }
                      />
                      {selectedMemberships.length > 0 && <Typography variant="caption">{selectedMemberships.length}</Typography>}
                    </Stack>
                  </TableCell>
                )}
                <TableCell>
                  <FormattedMessage id="users.customer" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="users.email" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="users.user" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="users.role" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="users.extension" />
                </TableCell>
                <TableCell align="right">
                  <FormattedMessage id="users.actions" />
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(data?.memberships || []).map((member) => (
                <TableRow key={member.membership_uuid}>
                  {session?.user_management?.superadmin && (
                    <TableCell padding="checkbox">
                      <Checkbox
                        checked={selectedMemberships.includes(member.membership_uuid)}
                        onChange={(event) =>
                          setSelectedMemberships((current) =>
                            event.target.checked
                              ? [...current, member.membership_uuid]
                              : current.filter((uuid) => uuid !== member.membership_uuid)
                          )
                        }
                      />
                    </TableCell>
                  )}
                  <TableCell>{member.customer_name || '—'}</TableCell>
                  <TableCell>{member.primary_email}</TableCell>
                  <TableCell>{member.username || '—'}</TableCell>
                  <TableCell>
                    <Select
                      variant="standard"
                      value={member.role}
                      disabled={savingId === member.membership_uuid || (member.role === 'owner' && !data?.capabilities?.superadmin)}
                      onChange={(event) => saveMember(member, { role: event.target.value })}
                    >
                      {[...(data?.capabilities?.superadmin ? ['owner'] : []), ...roles].map((role) => (
                        <MenuItem key={role} value={role}>
                          {intl.formatMessage({ id: `users.role.${role}` })}
                        </MenuItem>
                      ))}
                    </Select>
                  </TableCell>
                  <TableCell>{assignments.get(member.identity_uuid)?.join(', ') || '—'}</TableCell>
                  <TableCell align="right">
                    <Button size="small" disabled={savingId === member.membership_uuid} onClick={() => resend(member)}>
                      <FormattedMessage id="users.resend" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
        {data && data.memberships.length === 0 && (
          <Typography color="text.secondary">
            <FormattedMessage id="users.empty" />
          </Typography>
        )}
      </Stack>
      <Dialog open={inviteOpen} onClose={() => setInviteOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>
          <FormattedMessage id="users.invite" />
        </DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ pt: 1 }}>
            {!session?.identity && (
              <FormControl>
                <InputLabel>
                  <FormattedMessage id="users.customer" />
                </InputLabel>
                <Select
                  value={customerUuid}
                  label={intl.formatMessage({ id: 'users.customer' })}
                  onChange={(event) => setCustomerUuid(event.target.value)}
                >
                  {customers.map((customer) => (
                    <MenuItem key={customer.customer_uuid} value={customer.customer_uuid}>
                      {customer.display_name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            )}
            <TextField
              type="email"
              label={intl.formatMessage({ id: 'users.email' })}
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              helperText={intl.formatMessage({ id: 'users.inviteHelp' })}
            />
            <FormControl>
              <InputLabel>
                <FormattedMessage id="users.role" />
              </InputLabel>
              <Select
                value={inviteRole}
                label={intl.formatMessage({ id: 'users.role' })}
                onChange={(event) => setInviteRole(event.target.value)}
              >
                {roles.map((role) => (
                  <MenuItem key={role} value={role}>
                    {intl.formatMessage({ id: `users.role.${role}` })}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setInviteOpen(false)}>
            <FormattedMessage id="users.cancel" />
          </Button>
          <Button variant="contained" disabled={busy || !email} onClick={submitInvite}>
            <FormattedMessage id="users.sendInvite" />
          </Button>
        </DialogActions>
      </Dialog>
      <Dialog open={mergeOpen} onClose={() => !busy && setMergeOpen(false)} fullWidth maxWidth="md">
        <DialogTitle>
          <FormattedMessage id="users.merge.title" />
        </DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ pt: 1 }}>
            <Alert severity="warning">
              <FormattedMessage id="users.merge.warning" />
            </Alert>
            <FormControl>
              <InputLabel>
                <FormattedMessage id="users.merge.target" />
              </InputLabel>
              <Select
                value={mergeTarget}
                label={intl.formatMessage({ id: 'users.merge.target' })}
                onChange={(event) => {
                  setMergeTarget(event.target.value);
                  setMergePreview(null);
                }}
              >
                {customers
                  .filter(
                    (customer) =>
                      !(data?.memberships || []).some(
                        (member) => selectedMemberships.includes(member.membership_uuid) && member.customer_uuid === customer.customer_uuid
                      )
                  )
                  .map((customer) => (
                    <MenuItem key={customer.customer_uuid} value={customer.customer_uuid}>
                      {customer.display_name}
                    </MenuItem>
                  ))}
              </Select>
            </FormControl>
            <Button variant="outlined" disabled={busy || !mergeTarget || selectedMemberships.length === 0} onClick={previewMerge}>
              <FormattedMessage id="users.merge.preview" />
            </Button>
            {mergePreview && (
              <Stack spacing={1}>
                <Alert severity={mergePreview.valid ? 'success' : 'error'}>
                  <FormattedMessage id={mergePreview.valid ? 'users.merge.valid' : 'users.merge.invalid'} />
                </Alert>
                <Typography>
                  <FormattedMessage
                    id="users.merge.summary"
                    values={{
                      customers: mergePreview.summary.source_customers,
                      users: mergePreview.summary.memberships,
                      extensions: mergePreview.summary.extensions
                    }}
                  />
                </Typography>
                {(mergePreview.errors || []).map((item, index) => (
                  <Typography key={`${item.code}-${index}`} color="error">
                    <FormattedMessage id={`users.merge.error.${item.code}`} defaultMessage={item.code} />
                  </Typography>
                ))}
                {mergePreview.valid && (
                  <TextField
                    label={intl.formatMessage({ id: 'users.merge.confirmLabel' })}
                    helperText={intl.formatMessage({ id: 'users.merge.confirmHelp' })}
                    value={mergeConfirmation}
                    onChange={(event) => setMergeConfirmation(event.target.value)}
                  />
                )}
              </Stack>
            )}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button disabled={busy} onClick={() => setMergeOpen(false)}>
            <FormattedMessage id="users.cancel" />
          </Button>
          <Button
            color="warning"
            variant="contained"
            disabled={busy || !mergePreview?.valid || mergeConfirmation !== 'GOM'}
            onClick={executeMerge}
          >
            <FormattedMessage id="users.merge.execute" />
          </Button>
        </DialogActions>
      </Dialog>
    </MainCard>
  );
}
