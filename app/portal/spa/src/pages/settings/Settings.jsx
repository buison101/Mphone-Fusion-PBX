import { useEffect, useState } from 'react';
import PropTypes from 'prop-types';

import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Divider from '@mui/material/Divider';
import Grid from '@mui/material/Grid';
import Stack from '@mui/material/Stack';
import Switch from '@mui/material/Switch';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import { FormattedMessage, useIntl } from 'react-intl';

import MainCard from 'components/MainCard';
import ContentState from 'components/states/ContentState';
import useAnalytics from 'hooks/useAnalytics';
import useSession from 'hooks/useSession';
import { FORWARDING_URL, SETTINGS_URL } from 'config';

const types = ['all', 'busy', 'no_answer', 'not_registered'];

function ExtensionSettings({ extension, editable, csrf, onSaved }) {
  const intl = useIntl();
  const [form, setForm] = useState({ forwarding: extension.forwarding, call_timeout: extension.call_timeout });
  const [status, setStatus] = useState('');
  useEffect(() => setForm({ forwarding: extension.forwarding, call_timeout: extension.call_timeout }), [extension]);
  const changeForward = (type, key, value) =>
    setForm((current) => ({ ...current, forwarding: { ...current.forwarding, [type]: { ...current.forwarding[type], [key]: value } } }));
  const save = async () => {
    setStatus('saving');
    const response = await fetch(FORWARDING_URL, {
      method: 'PUT',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf },
      body: JSON.stringify({ extension_uuid: extension.extension_uuid, ...form })
    });
    setStatus(response.ok ? 'saved' : 'error');
    if (response.ok) onSaved();
  };

  return (
    <MainCard title={`${intl.formatMessage({ id: 'settings.extension' })} ${extension.extension}`}>
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, md: 6 }}>
          <Stack sx={{ gap: 1 }}>
            <Stack direction="row" sx={{ justifyContent: 'space-between' }}>
              <Typography>
                <FormattedMessage id="settings.registration" />
              </Typography>
              <Chip
                size="small"
                color={extension.registered ? 'success' : 'warning'}
                label={intl.formatMessage({ id: extension.registered ? 'settings.registered' : 'settings.unregistered' })}
              />
            </Stack>
            <Typography variant="body2" color="text.secondary">
              <FormattedMessage id="settings.devices" values={{ count: extension.registered_devices }} />
            </Typography>
            <Typography variant="body2">
              <FormattedMessage id="settings.callerId" />: {extension.caller_id_name || '—'} · {extension.caller_id_number || '—'}
            </Typography>
            <Typography variant="body2">
              <FormattedMessage id="settings.voicemail" />:{' '}
              {intl.formatMessage({ id: extension.voicemail.enabled ? 'common.enabled' : 'common.disabled' })}
            </Typography>
            <Typography variant="body2">
              <FormattedMessage id="settings.recordingPolicy" />: {extension.recording_policy || '—'}
            </Typography>
            <Typography variant="body2">
              <FormattedMessage id="settings.dnd" />:{' '}
              {intl.formatMessage({ id: extension.do_not_disturb ? 'common.enabled' : 'common.disabled' })}
            </Typography>
          </Stack>
        </Grid>
        <Grid size={{ xs: 12, md: 6 }}>
          <Typography variant="h6">
            <FormattedMessage id="settings.forwarding" />
          </Typography>
          <Stack sx={{ gap: 1.5, mt: 1 }}>
            {types.map((type) => (
              <Stack key={type} direction="row" sx={{ gap: 1, alignItems: 'center' }}>
                <Switch
                  disabled={!editable}
                  checked={form.forwarding[type].enabled}
                  onChange={(event) => changeForward(type, 'enabled', event.target.checked)}
                  inputProps={{ 'aria-label': intl.formatMessage({ id: `settings.forward.${type}` }) }}
                />
                <TextField
                  fullWidth
                  size="small"
                  disabled={!editable}
                  label={intl.formatMessage({ id: `settings.forward.${type}` })}
                  value={form.forwarding[type].destination}
                  onChange={(event) => changeForward(type, 'destination', event.target.value)}
                />
              </Stack>
            ))}
            <TextField
              size="small"
              type="number"
              disabled={!editable}
              label={intl.formatMessage({ id: 'settings.ringDuration' })}
              value={form.call_timeout}
              onChange={(event) => setForm((current) => ({ ...current, call_timeout: Number(event.target.value) }))}
              slotProps={{ htmlInput: { min: 5, max: 120 } }}
            />
            {editable && (
              <Button variant="contained" onClick={save} disabled={status === 'saving'}>
                <FormattedMessage id={status === 'saving' ? 'settings.saving' : 'settings.save'} />
              </Button>
            )}
            {status === 'saved' && (
              <Alert severity="success">
                <FormattedMessage id="settings.saved" />
              </Alert>
            )}
            {status === 'error' && (
              <Alert severity="error">
                <FormattedMessage id="settings.saveError" />
              </Alert>
            )}
          </Stack>
        </Grid>
      </Grid>
      <Divider sx={{ my: 2 }} />
      <Typography variant="caption" color="text.secondary">
        <FormattedMessage id="settings.securityNote" />
      </Typography>
    </MainCard>
  );
}

ExtensionSettings.propTypes = {
  extension: PropTypes.object.isRequired,
  editable: PropTypes.bool.isRequired,
  csrf: PropTypes.string.isRequired,
  onSaved: PropTypes.func.isRequired
};

export default function Settings() {
  const { session } = useSession();
  const { data, error, isLoading, refresh } = useAnalytics(SETTINGS_URL);
  return (
    <Stack sx={{ gap: 2.5 }}>
      <Typography variant="h2">
        <FormattedMessage id="settings.title" />
      </Typography>
      {isLoading && !data ? (
        <ContentState state="loading" title={<FormattedMessage id="table.loading" />} />
      ) : error ? (
        <ContentState
          state="error"
          title={<FormattedMessage id="table.error" />}
          actionLabel={<FormattedMessage id="action.retry" />}
          onAction={refresh}
        />
      ) : (data?.extensions ?? []).length === 0 ? (
        <ContentState state="empty" title={<FormattedMessage id="settings.empty" />} />
      ) : (
        data.extensions.map((extension) => (
          <ExtensionSettings
            key={extension.extension_uuid}
            extension={extension}
            editable={Boolean(data.capabilities?.forwarding_edit)}
            csrf={session.csrf}
            onSaved={refresh}
          />
        ))
      )}
    </Stack>
  );
}
