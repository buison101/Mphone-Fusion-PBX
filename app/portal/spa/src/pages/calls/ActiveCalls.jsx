import { useEffect, useState } from 'react';

// material-ui
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import Grid from '@mui/material/Grid';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Tooltip from '@mui/material/Tooltip';
import Typography from '@mui/material/Typography';

// third-party
import { FormattedMessage, useIntl } from 'react-intl';

// project imports
import MainCard from 'components/MainCard';
import StatCard from 'components/cards/statistics/StatCard';
import IconButton from 'components/@extended/IconButton';
import useActiveCalls from 'hooks/useActiveCalls';
import useSession from 'hooks/useSession';

// assets
import PhoneOutlined from '@ant-design/icons/PhoneOutlined';
import ArrowDownOutlined from '@ant-design/icons/ArrowDownOutlined';
import ArrowUpOutlined from '@ant-design/icons/ArrowUpOutlined';
import SwapOutlined from '@ant-design/icons/SwapOutlined';
import DisconnectOutlined from '@ant-design/icons/DisconnectOutlined';

const directionIcon = {
  inbound: <ArrowDownOutlined style={{ fontSize: '0.875rem' }} />,
  outbound: <ArrowUpOutlined style={{ fontSize: '0.875rem' }} />,
  local: <SwapOutlined style={{ fontSize: '0.875rem' }} />,
  voicemail: <PhoneOutlined style={{ fontSize: '0.875rem' }} />
};

const stateColor = { ringing: 'warning', answered: 'success', early: 'info' };

const STATE_MESSAGE = { ringing: 'callState.ringing', answered: 'callState.answered' };
const DIRECTION_MESSAGE = {
  inbound: 'direction.inbound',
  outbound: 'direction.outbound',
  local: 'direction.local',
  voicemail: 'direction.voicemail'
};

// The switch reports the channel creation time in microseconds since the epoch.
// One clock ticks for the whole table rather than a timer per row.
function formatElapsed(createdTime, now) {
  if (!createdTime) return '—';

  const seconds = Math.max(Math.floor((now - Number(createdTime) / 1000) / 1000), 0);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const pad = (value) => String(value).padStart(2, '0');

  return hours > 0 ? `${hours}:${pad(minutes % 60)}:${pad(seconds % 60)}` : `${minutes}:${pad(seconds % 60)}`;
}

function useClock() {
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);

  return now;
}

function CallRow({ call, canHangup, onHangup, now }) {
  const intl = useIntl();
  const elapsed = formatElapsed(call.created_time, now);
  const state = call.answer_state || 'unknown';
  const stateLabel = intl.formatMessage({ id: STATE_MESSAGE[state] ?? 'callState.unknown' });
  const directionLabel = intl.formatMessage({ id: DIRECTION_MESSAGE[call.direction] ?? 'direction.unknown' });

  return (
    <TableRow hover>
      <TableCell>
        <Stack direction="row" sx={{ alignItems: 'center', gap: 1 }}>
          <Box sx={{ color: 'text.secondary', display: 'flex' }}>
            {directionIcon[call.direction] ?? <PhoneOutlined style={{ fontSize: '0.875rem' }} />}
          </Box>
          <Typography variant="body2">{directionLabel}</Typography>
        </Stack>
      </TableCell>
      <TableCell>
        <Stack>
          <Typography variant="subtitle2">{call.caller_caller_id_name || '—'}</Typography>
          <Typography variant="caption" sx={{ color: 'text.secondary' }}>
            {call.caller_caller_id_number || ''}
          </Typography>
        </Stack>
      </TableCell>
      <TableCell>
        <Typography variant="body2">{call.caller_destination_number || '—'}</Typography>
      </TableCell>
      <TableCell>
        <Chip size="small" variant="combined" color={stateColor[state] ?? 'secondary'} label={stateLabel} />
      </TableCell>
      <TableCell align="right">
        <Typography variant="body2" sx={{ fontVariantNumeric: 'tabular-nums' }}>
          {elapsed}
        </Typography>
      </TableCell>
      {canHangup && (
        <TableCell align="right">
          <Tooltip title={intl.formatMessage({ id: 'calls.hangup' })}>
            <IconButton size="small" color="error" onClick={() => onHangup(call.unique_id)} aria-label="hangup">
              <DisconnectOutlined />
            </IconButton>
          </Tooltip>
        </TableCell>
      )}
    </TableRow>
  );
}

// ==============================|| CALLS - ACTIVE ||============================== //

export default function ActiveCalls() {
  const { calls, status, hangup } = useActiveCalls();
  const { can } = useSession();
  const intl = useIntl();
  const now = useClock();
  const canHangup = can('call_active_hangup');

  const ringing = calls.filter((call) => call.answer_state === 'ringing').length;
  const answered = calls.filter((call) => call.answer_state === 'answered').length;
  const waiting = status !== 'subscribed' && calls.length === 0;

  return (
    <Grid container spacing={2.5}>
      <Grid size={12}>
        <Typography variant="h2">
          <FormattedMessage id="calls.title" />
        </Typography>
      </Grid>
      <Grid size={{ xs: 12, sm: 4 }}>
        <StatCard title={intl.formatMessage({ id: 'calls.total' })} count={calls.length} />
      </Grid>
      <Grid size={{ xs: 12, sm: 4 }}>
        <StatCard title={intl.formatMessage({ id: 'calls.ringing' })} count={ringing} color="warning" />
      </Grid>
      <Grid size={{ xs: 12, sm: 4 }}>
        <StatCard title={intl.formatMessage({ id: 'calls.connected' })} count={answered} color="success" />
      </Grid>

      <Grid size={12}>
        <MainCard content={false}>
          <TableContainer sx={{ overflowX: 'auto' }}>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>
                    <FormattedMessage id="table.direction" />
                  </TableCell>
                  <TableCell>
                    <FormattedMessage id="table.caller" />
                  </TableCell>
                  <TableCell>
                    <FormattedMessage id="table.destination" />
                  </TableCell>
                  <TableCell>
                    <FormattedMessage id="table.state" />
                  </TableCell>
                  <TableCell align="right">
                    <FormattedMessage id="table.duration" />
                  </TableCell>
                  {canHangup && <TableCell align="right" />}
                </TableRow>
              </TableHead>
              <TableBody>
                {calls.map((call) => (
                  <CallRow key={call.unique_id} call={call} canHangup={canHangup} onHangup={hangup} now={now} />
                ))}
                {calls.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={canHangup ? 6 : 5} align="center" sx={{ py: 6 }}>
                      <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                        <FormattedMessage id={waiting ? 'calls.connecting' : 'calls.empty'} />
                      </Typography>
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </MainCard>
      </Grid>
    </Grid>
  );
}
