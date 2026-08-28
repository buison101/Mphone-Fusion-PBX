import { useEffect, useState } from 'react';

import Alert from '@mui/material/Alert';
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Grid from '@mui/material/Grid';
import MenuItem from '@mui/material/MenuItem';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import { FormattedMessage, useIntl } from 'react-intl';
import PropTypes from 'prop-types';

import MainCard from 'components/MainCard';
import ContentState from 'components/states/ContentState';
import useAnalytics from 'hooks/useAnalytics';
import useSession from 'hooks/useSession';
import { ACCOUNT_URL, GOOGLE_OAUTH_URL } from 'config';

function IdentityAccount({ session }) {
  const intl = useIntl();
  const { lifecycle } = useSession();
  const { data, error, isLoading, refresh } = useAnalytics(ACCOUNT_URL);
  const [busy, setBusy] = useState('');
  const [feedback, setFeedback] = useState('');
  const [showHistory, setShowHistory] = useState(false);
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [newPasswordConfirm, setNewPasswordConfirm] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [googlePassword, setGooglePassword] = useState('');
  const [googleLinkReady, setGoogleLinkReady] = useState(new URLSearchParams(window.location.search).get('google') === 'link_ready');
  const [profile, setProfile] = useState({ full_name: '', phone_number: '', locale: 'vi-VN', timezone: 'Asia/Ho_Chi_Minh', version: 1 });

  useEffect(() => {
    if (!data?.identity) return;
    setProfile({
      full_name: data.identity.full_name || '',
      phone_number: data.identity.phone_number || '',
      locale: data.identity.locale || 'vi-VN',
      timezone: data.identity.timezone || 'Asia/Ho_Chi_Minh',
      version: data.identity.profile_version || 1
    });
  }, [data?.identity]);

  const googleProvider = (data?.providers ?? []).find((provider) => provider.provider === 'google');

  const postAction = async (body) => {
    const response = await fetch(ACCOUNT_URL, {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session?.csrf || '' },
      body: JSON.stringify(body)
    });
    const payload = await response.json().catch(() => ({}));
    return { response, payload };
  };

  const revoke = async (device) => {
    if (!window.confirm(intl.formatMessage({ id: 'account.devices.revokeConfirm' }))) return;
    setBusy(device.session_id);
    setFeedback('');
    const { response, payload } = await postAction({ action: 'revoke_device', session_id: device.session_id });
    if (response.ok && payload.current) {
      window.location.reload();
      return;
    }
    setFeedback(response.ok ? 'revoked' : 'error');
    setBusy('');
    if (response.ok) refresh();
  };

  const logoutOthers = async () => {
    if (!window.confirm(intl.formatMessage({ id: 'account.logoutAllConfirm' }))) return;
    setBusy('all');
    setFeedback('');
    const { response } = await postAction({ action: 'logout_others' });
    if (response.ok) {
      setFeedback('othersRevoked');
      setBusy('');
      refresh();
      return;
    }
    setFeedback('error');
    setBusy('');
  };

  const changePassword = async (event) => {
    event.preventDefault();
    if (newPassword !== newPasswordConfirm) {
      setFeedback('passwordMismatch');
      return;
    }
    setBusy('password');
    setFeedback('');
    const result = await lifecycle(
      {
        action: 'change_password',
        current_password: currentPassword,
        new_password: newPassword
      },
      true
    );
    setBusy('');
    if (!result.ok) {
      setFeedback(result.data?.error === 'recent_auth_failed' ? 'reauthError' : 'error');
      return;
    }
    setCurrentPassword('');
    setNewPassword('');
    setNewPasswordConfirm('');
    setFeedback('passwordChanged');
    refresh();
  };

  const requestEmailChange = async (event) => {
    event.preventDefault();
    setBusy('email');
    setFeedback('');
    const result = await lifecycle(
      {
        action: 'request_email_change',
        current_password: currentPassword,
        new_email: newEmail
      },
      true
    );
    setBusy('');
    if (!result.ok) {
      setFeedback(
        result.data?.error === 'recent_auth_failed'
          ? 'reauthError'
          : result.data?.error === 'email_unavailable'
            ? 'emailUnavailable'
            : result.data?.error === 'delivery_failed'
              ? 'emailDeliveryFailed'
              : 'error'
      );
      return;
    }
    setCurrentPassword('');
    setNewEmail('');
    setFeedback('emailChangeSent');
  };

  const finishGoogleLink = async (event) => {
    event.preventDefault();
    setBusy('google');
    setFeedback('');
    const { response, payload } = await postAction({ action: 'link_google', current_password: googlePassword });
    setBusy('');
    setGooglePassword('');
    window.history.replaceState({}, '', '/p/account');
    setGoogleLinkReady(false);
    if (!response.ok) {
      setFeedback(payload.error === 'recent_auth_failed' ? 'reauthError' : 'googleLinkError');
      return;
    }
    setFeedback('googleLinked');
    refresh();
  };

  const unlinkGoogle = async (event) => {
    event.preventDefault();
    setBusy('google');
    setFeedback('');
    const { response, payload } = await postAction({ action: 'unlink_google', current_password: googlePassword });
    setBusy('');
    setGooglePassword('');
    if (!response.ok) {
      setFeedback(payload.error === 'recent_auth_failed' ? 'reauthError' : 'googleUnlinkError');
      return;
    }
    setFeedback('googleUnlinked');
    refresh();
  };

  const saveProfile = async (event) => {
    event.preventDefault();
    setBusy('profile');
    setFeedback('');
    const { response, payload } = await postAction({ action: 'update_profile', ...profile });
    setBusy('');
    if (!response.ok) {
      setFeedback(payload.error === 'profile_conflict' ? 'profileConflict' : 'profileError');
      if (payload.error === 'profile_conflict') refresh();
      return;
    }
    setFeedback('profileSaved');
    refresh();
  };

  const uploadAvatar = async (event) => {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (!file) return;
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > 2 * 1024 * 1024) {
      setFeedback('avatarInvalid');
      return;
    }
    setBusy('avatar');
    setFeedback('');
    const dataUrl = await new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(String(reader.result || ''));
      reader.onerror = reject;
      reader.readAsDataURL(file);
    }).catch(() => '');
    const encoded = dataUrl.includes(',') ? dataUrl.split(',')[1] : '';
    const { response } = encoded
      ? await postAction({ action: 'update_avatar', content_type: file.type, data: encoded })
      : { response: { ok: false } };
    setBusy('');
    if (!response.ok) {
      setFeedback('avatarError');
      return;
    }
    setFeedback('avatarSaved');
    refresh();
  };

  if (isLoading && !data) return <ContentState state="loading" title={<FormattedMessage id="table.loading" />} />;
  if (error) {
    return (
      <ContentState
        state="error"
        title={<FormattedMessage id="table.error" />}
        actionLabel={<FormattedMessage id="action.retry" />}
        onAction={refresh}
      />
    );
  }

  const activeDevices = (data?.devices ?? []).filter((device) => !device.revoked_at);
  const historicalDevices = (data?.devices ?? []).filter((device) => device.revoked_at);
  const visibleDevices = showHistory ? (data?.devices ?? []) : activeDevices;
  const date = (value) => (value ? intl.formatDate(value, { dateStyle: 'medium', timeStyle: 'short' }) : '—');

  return (
    <Stack sx={{ gap: 2.5 }}>
      <Typography variant="h2">
        <FormattedMessage id="account.title" />
      </Typography>
      {feedback === 'revoked' && (
        <Alert severity="success">
          <FormattedMessage id="account.devices.revoked" />
        </Alert>
      )}
      {feedback === 'othersRevoked' && (
        <Alert severity="success">
          <FormattedMessage id="account.devices.othersRevoked" />
        </Alert>
      )}
      {feedback === 'error' && (
        <Alert severity="error">
          <FormattedMessage id="account.error" />
        </Alert>
      )}
      {['passwordChanged', 'emailChangeSent', 'googleLinked', 'googleUnlinked', 'profileSaved', 'avatarSaved'].includes(feedback) && (
        <Alert severity="success">
          <FormattedMessage id={`account.security.${feedback}`} />
        </Alert>
      )}
      {['passwordMismatch', 'reauthError', 'emailUnavailable', 'emailDeliveryFailed', 'googleLinkError', 'googleUnlinkError',
        'profileConflict', 'profileError', 'avatarInvalid', 'avatarError'].includes(
        feedback
      ) && (
        <Alert severity="error">
          <FormattedMessage id={`account.security.${feedback}`} />
        </Alert>
      )}
      <Grid container spacing={2.5}>
        <Grid size={{ xs: 12, md: 6 }}>
          <MainCard title={<FormattedMessage id="account.profile" />}>
            <Stack component="form" onSubmit={saveProfile} sx={{ gap: 1.5 }}>
              <Stack direction="row" sx={{ gap: 2, alignItems: 'center' }}>
                <Avatar
                  src={data?.identity?.avatar_version > 0 ? `${ACCOUNT_URL}?resource=avatar&v=${data.identity.avatar_version}` : undefined}
                  sx={{ width: 72, height: 72, fontSize: 24 }}
                >
                  {(profile.full_name || data?.identity?.primary_email || '?').trim().charAt(0).toUpperCase()}
                </Avatar>
                <Button component="label" variant="outlined" disabled={busy !== ''}>
                  <FormattedMessage id="account.profile.avatar" />
                  <input hidden type="file" accept="image/jpeg,image/png,image/webp" onChange={uploadAvatar} />
                </Button>
              </Stack>
              <TextField
                label={<FormattedMessage id="account.profile.fullName" />}
                value={profile.full_name}
                inputProps={{ maxLength: 120 }}
                onChange={(event) => setProfile((current) => ({ ...current, full_name: event.target.value }))}
              />
              <TextField
                label={<FormattedMessage id="account.profile.phone" />}
                value={profile.phone_number}
                inputProps={{ maxLength: 32 }}
                onChange={(event) => setProfile((current) => ({ ...current, phone_number: event.target.value }))}
              />
              <TextField
                select
                label={<FormattedMessage id="account.profile.language" />}
                value={profile.locale}
                onChange={(event) => setProfile((current) => ({ ...current, locale: event.target.value }))}
              >
                <MenuItem value="vi-VN"><FormattedMessage id="account.profile.language.vi" /></MenuItem>
                <MenuItem value="en"><FormattedMessage id="account.profile.language.en" /></MenuItem>
              </TextField>
              <TextField
                label={<FormattedMessage id="account.profile.timezone" />}
                value={profile.timezone}
                inputProps={{ maxLength: 64 }}
                onChange={(event) => setProfile((current) => ({ ...current, timezone: event.target.value }))}
              />
              <Stack>
                <Typography variant="caption" color="text.secondary">
                  <FormattedMessage id="account.email" />
                </Typography>
                <Typography>{data?.identity?.primary_email || '—'}</Typography>
              </Stack>
              <Stack>
                <Typography variant="caption" color="text.secondary">
                  <FormattedMessage id="account.emailStatus" />
                </Typography>
                <Chip
                  size="small"
                  color={data?.identity?.email_verified_at ? 'success' : 'warning'}
                  label={intl.formatMessage({ id: data?.identity?.email_verified_at ? 'account.verified' : 'account.unverified' })}
                  sx={{ alignSelf: 'flex-start' }}
                />
              </Stack>
              <Stack>
                <Typography variant="caption" color="text.secondary">
                  <FormattedMessage id="account.customer" />
                </Typography>
                <Typography>{data?.customer?.display_name || '—'}</Typography>
              </Stack>
              <Stack>
                <Typography variant="caption" color="text.secondary">
                  <FormattedMessage id="account.role" />
                </Typography>
                <Typography>{data?.membership?.role || '—'}</Typography>
              </Stack>
              <Button type="submit" variant="contained" disabled={busy !== ''}>
                <FormattedMessage id="account.profile.save" />
              </Button>
            </Stack>
          </MainCard>
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <MainCard title={<FormattedMessage id="account.extensions" />}>
            <Stack sx={{ gap: 1.5 }}>
              {(data?.extensions ?? []).map((extension) => (
                <Stack
                  key={extension.extension_uuid}
                  direction="row"
                  sx={{ justifyContent: 'space-between', alignItems: 'center', gap: 1 }}
                >
                  <Stack>
                    <Typography>{extension.extension}</Typography>
                    <Typography variant="caption" color="text.secondary">
                      {extension.display_name || '—'}
                    </Typography>
                  </Stack>
                  <Stack direction="row" sx={{ gap: 0.75 }}>
                    <Chip
                      size="small"
                      color={extension.can_use ? 'success' : 'default'}
                      label={intl.formatMessage({ id: 'account.canUse' })}
                    />
                    <Chip
                      size="small"
                      color={extension.can_manage ? 'primary' : 'default'}
                      label={intl.formatMessage({ id: 'account.canManage' })}
                    />
                  </Stack>
                </Stack>
              ))}
              {(data?.extensions ?? []).length === 0 && (
                <Typography color="text.secondary">
                  <FormattedMessage id="account.extensions.empty" />
                </Typography>
              )}
            </Stack>
          </MainCard>
        </Grid>
      </Grid>

      <MainCard title={<FormattedMessage id="account.devices" />}>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>
                  <FormattedMessage id="account.devices.name" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="account.devices.lastSeen" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="account.devices.created" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="account.devices.expires" />
                </TableCell>
                <TableCell>
                  <FormattedMessage id="account.devices.status" />
                </TableCell>
                <TableCell align="right">
                  <FormattedMessage id="account.devices.action" />
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {visibleDevices.map((device) => (
                <TableRow key={device.session_id}>
                  <TableCell>
                    <Stack>
                      <Stack direction="row" sx={{ gap: 0.75, alignItems: 'center' }}>
                        <Typography>{device.device_name || intl.formatMessage({ id: 'account.devices.unknown' })}</Typography>
                        {device.current && (
                          <Chip size="small" color="primary" label={intl.formatMessage({ id: 'account.devices.current' })} />
                        )}
                      </Stack>
                      <Typography variant="caption" color="text.secondary">
                        {device.client_type} {device.app_version ? `· ${device.app_version}` : ''}
                      </Typography>
                    </Stack>
                  </TableCell>
                  <TableCell>{date(device.last_seen_at)}</TableCell>
                  <TableCell>{date(device.created_at)}</TableCell>
                  <TableCell>{date(device.expires_at)}</TableCell>
                  <TableCell>
                    <Chip
                      size="small"
                      color={device.revoked_at ? 'default' : 'success'}
                      label={intl.formatMessage({ id: device.revoked_at ? 'account.devices.revokedStatus' : 'account.devices.active' })}
                    />
                  </TableCell>
                  <TableCell align="right">
                    {!device.revoked_at && !device.current && (
                      <Button color="error" size="small" disabled={busy !== ''} onClick={() => revoke(device)}>
                        <FormattedMessage id="account.devices.revoke" />
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
              {activeDevices.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6}>
                    <FormattedMessage id="account.devices.empty" />
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
        {historicalDevices.length > 0 && (
          <Button size="small" sx={{ mt: 1.5 }} onClick={() => setShowHistory((value) => !value)}>
            <FormattedMessage
              id={showHistory ? 'account.devices.hideHistory' : 'account.devices.showHistory'}
              values={{ count: historicalDevices.length }}
            />
          </Button>
        )}
      </MainCard>

      <Grid container spacing={2.5}>
        <Grid size={{ xs: 12, md: 6 }}>
          <MainCard title={<FormattedMessage id="account.security.changePassword" />}>
            <Stack component="form" onSubmit={changePassword} sx={{ gap: 1.5 }}>
              <TextField
                type="password"
                autoComplete="current-password"
                label={<FormattedMessage id="account.security.currentPassword" />}
                value={currentPassword}
                onChange={(event) => setCurrentPassword(event.target.value)}
                required
              />
              <TextField
                type="password"
                autoComplete="new-password"
                label={<FormattedMessage id="account.security.newPassword" />}
                helperText={<FormattedMessage id="lifecycle.passwordHelp" />}
                inputProps={{ minLength: 12, maxLength: 128 }}
                value={newPassword}
                onChange={(event) => setNewPassword(event.target.value)}
                required
              />
              <TextField
                type="password"
                autoComplete="new-password"
                label={<FormattedMessage id="account.security.confirmPassword" />}
                inputProps={{ minLength: 12, maxLength: 128 }}
                value={newPasswordConfirm}
                onChange={(event) => setNewPasswordConfirm(event.target.value)}
                required
              />
              <Button type="submit" variant="contained" disabled={busy !== ''}>
                <FormattedMessage id="account.security.changePassword" />
              </Button>
            </Stack>
          </MainCard>
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <MainCard title={<FormattedMessage id="account.security.changeEmail" />}>
            <Stack component="form" onSubmit={requestEmailChange} sx={{ gap: 1.5 }}>
              <TextField
                type="email"
                autoComplete="email"
                label={<FormattedMessage id="account.security.newEmail" />}
                value={newEmail}
                onChange={(event) => setNewEmail(event.target.value)}
                required
              />
              <TextField
                type="password"
                autoComplete="current-password"
                label={<FormattedMessage id="account.security.currentPassword" />}
                value={currentPassword}
                onChange={(event) => setCurrentPassword(event.target.value)}
                required
              />
              <Typography variant="body2" color="text.secondary">
                <FormattedMessage id="account.security.changeEmailHelp" />
              </Typography>
              <Button type="submit" variant="contained" disabled={busy !== ''}>
                <FormattedMessage id="account.security.sendEmailConfirmation" />
              </Button>
            </Stack>
          </MainCard>
        </Grid>
      </Grid>

      <MainCard title={<FormattedMessage id="account.providers.title" />}>
        <Stack sx={{ gap: 1.5 }}>
          <Stack direction={{ xs: 'column', sm: 'row' }} sx={{ justifyContent: 'space-between', alignItems: { sm: 'center' }, gap: 1.5 }}>
            <Stack>
              <Typography>Google</Typography>
              <Typography variant="body2" color="text.secondary">
                <FormattedMessage id={googleProvider ? 'account.providers.googleLinked' : 'account.providers.googleNotLinked'} />
              </Typography>
            </Stack>
            {!googleProvider && !googleLinkReady && data?.google_enabled && (
              <Button component="a" href={`${GOOGLE_OAUTH_URL}?action=start&flow=link`} variant="outlined">
                <FormattedMessage id="account.providers.linkGoogle" />
              </Button>
            )}
          </Stack>
          {googleLinkReady && (
            <Stack component="form" onSubmit={finishGoogleLink} direction={{ xs: 'column', sm: 'row' }} sx={{ gap: 1.5 }}>
              <TextField
                type="password"
                autoComplete="current-password"
                label={<FormattedMessage id="account.security.currentPassword" />}
                value={googlePassword}
                onChange={(event) => setGooglePassword(event.target.value)}
                required
                fullWidth
              />
              <Button type="submit" variant="contained" disabled={busy !== ''}>
                <FormattedMessage id="account.providers.confirmLink" />
              </Button>
            </Stack>
          )}
          {googleProvider && (
            <Stack component="form" onSubmit={unlinkGoogle} direction={{ xs: 'column', sm: 'row' }} sx={{ gap: 1.5 }}>
              <TextField
                type="password"
                autoComplete="current-password"
                label={<FormattedMessage id="account.security.currentPassword" />}
                value={googlePassword}
                onChange={(event) => setGooglePassword(event.target.value)}
                required
                fullWidth
              />
              <Button type="submit" color="error" variant="outlined" disabled={busy !== ''}>
                <FormattedMessage id="account.providers.unlinkGoogle" />
              </Button>
            </Stack>
          )}
        </Stack>
      </MainCard>

      <MainCard title={<FormattedMessage id="account.danger" />}>
        <Stack direction={{ xs: 'column', sm: 'row' }} sx={{ justifyContent: 'space-between', alignItems: { sm: 'center' }, gap: 2 }}>
          <Stack>
            <Typography>
              <FormattedMessage id="account.logoutAll" />
            </Typography>
            <Typography variant="body2" color="text.secondary">
              <FormattedMessage id="account.logoutAllHelp" />
            </Typography>
          </Stack>
          <Button color="error" variant="outlined" disabled={busy !== ''} onClick={logoutOthers}>
            <FormattedMessage id="account.logoutAll" />
          </Button>
        </Stack>
      </MainCard>
    </Stack>
  );
}

IdentityAccount.propTypes = { session: PropTypes.object.isRequired };

export default function Account() {
  const { session, logout } = useSession();

  if (!session?.identity) {
    return (
      <ContentState
        state="forbidden"
        title={<FormattedMessage id="account.identityRequired.title" />}
        detail={<FormattedMessage id="account.identityRequired.detail" />}
        actionLabel={<FormattedMessage id="account.identityRequired.action" />}
        onAction={logout}
      />
    );
  }

  return <IdentityAccount session={session} />;
}
