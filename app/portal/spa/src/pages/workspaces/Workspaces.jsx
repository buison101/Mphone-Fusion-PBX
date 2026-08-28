import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FormattedMessage, useIntl } from 'react-intl';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Grid from '@mui/material/Grid';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import MainCard from 'components/MainCard';
import ContentState from 'components/states/ContentState';
import useSession from 'hooks/useSession';
import { WORKSPACES_URL } from 'config';

export default function Workspaces() {
  const intl = useIntl();
  const navigate = useNavigate();
  const { session, reload } = useSession();
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState('');

  const load = useCallback(async () => {
    try {
      const response = await fetch(WORKSPACES_URL, { credentials: 'same-origin' });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable');
      setData(payload);
      setError('');
    } catch (caught) {
      setError(caught.message);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const switchWorkspace = async (customerUuid) => {
    setBusy(customerUuid);
    setError('');
    try {
      const response = await fetch(WORKSPACES_URL, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session?.csrf || '' },
        body: JSON.stringify({ customer_uuid: customerUuid })
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(payload.error || 'service_unavailable');
      await reload();
      navigate('/dashboard');
    } catch (caught) {
      setError(caught.message);
      setBusy('');
    }
  };

  if (!data && !error) return <ContentState state="loading" title={<FormattedMessage id="table.loading" />} />;
  if (!data && error) {
    return <ContentState state="error" title={<FormattedMessage id="table.error" />} actionLabel={<FormattedMessage id="action.retry" />} onAction={load} />;
  }

  const memberships = data?.memberships || [];
  return (
    <Stack spacing={2.5}>
      <Stack>
        <Typography variant="h2"><FormattedMessage id="workspaces.title" /></Typography>
        <Typography color="text.secondary"><FormattedMessage id="workspaces.subtitle" /></Typography>
      </Stack>
      {error && <Alert severity="error"><FormattedMessage id={`workspaces.error.${error}`} defaultMessage={intl.formatMessage({ id: 'workspaces.error.generic' })} /></Alert>}
      {memberships.length === 0 ? (
        <ContentState state="empty" title={<FormattedMessage id="workspaces.empty.title" />} detail={<FormattedMessage id="workspaces.empty.description" />} />
      ) : (
        <Grid container spacing={2.5}>
          {memberships.map((membership) => {
            const current = membership.customer_uuid === data.active_customer_uuid;
            const typeLabel = membership.customer_type === 'organization' ? 'workspaces.type.organization' : 'workspaces.type.personal';
            return (
              <Grid key={membership.membership_uuid} size={{ xs: 12, md: 6, lg: 4 }}>
                <MainCard>
                  <Stack spacing={1.5}>
                    <Stack direction="row" sx={{ justifyContent: 'space-between', alignItems: 'flex-start', gap: 1 }}>
                      <Stack sx={{ minWidth: 0 }}>
                        <Typography variant="h5" noWrap>{membership.display_name}</Typography>
                        <Typography variant="body2" color="text.secondary"><FormattedMessage id={typeLabel} /></Typography>
                      </Stack>
                      {current && <Chip size="small" color="primary" label={intl.formatMessage({ id: 'workspaces.current' })} />}
                    </Stack>
                    <Typography variant="body2"><FormattedMessage id="workspaces.role" values={{ role: intl.formatMessage({ id: `workspaces.roles.${membership.role}` }) }} /></Typography>
                    <Button
                      variant={current ? 'outlined' : 'contained'}
                      disabled={current || busy !== ''}
                      onClick={() => switchWorkspace(membership.customer_uuid)}
                    >
                      <FormattedMessage id={current ? 'workspaces.inUse' : 'workspaces.switch'} />
                    </Button>
                  </Stack>
                </MainCard>
              </Grid>
            );
          })}
        </Grid>
      )}
    </Stack>
  );
}
