import Alert from '@mui/material/Alert';
import Chip from '@mui/material/Chip';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Typography from '@mui/material/Typography';
import { FormattedMessage, useIntl } from 'react-intl';

import MainCard from 'components/MainCard';
import ContentState from 'components/states/ContentState';
import useAnalytics from 'hooks/useAnalytics';
import { CUSTOMER_URL } from 'config';

export default function CustomerSecurity() {
  const intl = useIntl();
  const { data, error, isLoading } = useAnalytics(CUSTOMER_URL, { resource: 'security' });
  if (isLoading) return <ContentState loading />;
  if (error) return <Alert severity="error"><FormattedMessage id="customer.loadError" /></Alert>;
  const events = data?.events || [];
  const exceptions = data?.reconciliation_exceptions || [];
  const sessions = data?.sessions || [];
  const authenticationEvents = data?.authentication_events || [];
  return <Stack spacing={2}>
    <Typography variant="h4"><FormattedMessage id="customer.securityTitle" /></Typography>
    {exceptions.some((item) => !item.resolved_at) && <Alert severity="warning"><FormattedMessage id="customer.securityExceptions" /></Alert>}
    <MainCard title={<FormattedMessage id="customer.sessionsTitle" />} content={false}>
      <TableContainer><Table><TableHead><TableRow>
        <TableCell><FormattedMessage id="customer.userIdentity" /></TableCell>
        <TableCell><FormattedMessage id="customer.device" /></TableCell>
        <TableCell><FormattedMessage id="customer.lastSeen" /></TableCell>
        <TableCell><FormattedMessage id="customer.state" /></TableCell>
      </TableRow></TableHead><TableBody>
        {sessions.map((item) => <TableRow key={item.session_uuid}>
          <TableCell>{item.identity_email || '—'}</TableCell>
          <TableCell>{item.device_name || item.platform || item.client_type || '—'}</TableCell>
          <TableCell>{new Date(item.last_seen_at || item.created_at).toLocaleString(intl.locale)}</TableCell>
          <TableCell><Chip size="small" color={item.state === 'active' ? 'success' : 'default'}
            label={intl.formatMessage({ id: `customer.sessionState.${item.state}` }) + (item.is_current ? ` · ${intl.formatMessage({ id: 'customer.currentSession' })}` : '')} /></TableCell>
        </TableRow>)}
        {!sessions.length && <TableRow><TableCell colSpan={4}><FormattedMessage id="customer.sessionsEmpty" /></TableCell></TableRow>}
      </TableBody></Table></TableContainer>
    </MainCard>
    <MainCard title={<FormattedMessage id="customer.authenticationTitle" />} content={false}>
      <TableContainer><Table><TableHead><TableRow>
        <TableCell><FormattedMessage id="customer.time" /></TableCell>
        <TableCell><FormattedMessage id="customer.userIdentity" /></TableCell>
        <TableCell><FormattedMessage id="customer.action" /></TableCell>
        <TableCell><FormattedMessage id="customer.device" /></TableCell>
        <TableCell><FormattedMessage id="customer.result" /></TableCell>
      </TableRow></TableHead><TableBody>
        {authenticationEvents.map((item) => <TableRow key={item.event_uuid}>
          <TableCell>{new Date(item.created_at).toLocaleString(intl.locale)}</TableCell>
          <TableCell>{item.identity_email || '—'}</TableCell>
          <TableCell>{item.event_type}</TableCell><TableCell>{item.user_agent_summary || '—'}</TableCell>
          <TableCell><Chip size="small" color={item.result === 'accepted' ? 'success' : 'default'} label={item.result} /></TableCell>
        </TableRow>)}
        {!authenticationEvents.length && <TableRow><TableCell colSpan={5}><FormattedMessage id="customer.authenticationEmpty" /></TableCell></TableRow>}
      </TableBody></Table></TableContainer>
    </MainCard>
    <MainCard title={<FormattedMessage id="customer.auditTitle" />} content={false}>
      <TableContainer><Table><TableHead><TableRow>
        <TableCell><FormattedMessage id="customer.time" /></TableCell>
        <TableCell><FormattedMessage id="customer.action" /></TableCell>
        <TableCell><FormattedMessage id="customer.target" /></TableCell>
        <TableCell><FormattedMessage id="customer.result" /></TableCell>
      </TableRow></TableHead><TableBody>
        {events.map((item) => <TableRow key={item.event_uuid}>
          <TableCell>{new Date(item.created_at).toLocaleString(intl.locale)}</TableCell>
          <TableCell>{item.action}</TableCell><TableCell>{item.target_type || '—'}</TableCell>
          <TableCell><Chip size="small" color={item.result === 'accepted' ? 'success' : 'default'} label={item.result} /></TableCell>
        </TableRow>)}
        {!events.length && <TableRow><TableCell colSpan={4}><FormattedMessage id="customer.auditEmpty" /></TableCell></TableRow>}
      </TableBody></Table></TableContainer>
    </MainCard>
  </Stack>;
}
