import { useState } from 'react';

// material-ui
import Grid from '@mui/material/Grid';
import Stack from '@mui/material/Stack';
import ToggleButton from '@mui/material/ToggleButton';
import ToggleButtonGroup from '@mui/material/ToggleButtonGroup';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Typography from '@mui/material/Typography';
import Chip from '@mui/material/Chip';
import Box from '@mui/material/Box';
import { PieChart } from '@mui/x-charts/PieChart';

// third-party
import { FormattedMessage, useIntl } from 'react-intl';

// project imports
import MainCard from 'components/MainCard';
import StatCard from 'components/cards/statistics/StatCard';
import CallVolumeChart from 'sections/dashboard/CallVolumeChart';
import useDashboard from 'hooks/useDashboard';
import useActiveCalls from 'hooks/useActiveCalls';
import { STATUS_COLOR } from 'utils/callStatus';

const RANGES = [
  { value: 24, labelId: 'overview.range.24h' },
  { value: 168, labelId: 'overview.range.7d' },
  { value: 720, labelId: 'overview.range.30d' },
  { value: 2160, labelId: 'overview.range.90d' }
];

const STATUS_CHART_COLOR = {
  answered: '#1677ff',
  missed: '#ff4d4f',
  no_answer: '#8c8c8c',
  busy: '#faad14',
  voicemail: '#13c2c2',
  cancelled: '#722ed1',
  failed: '#d4380d'
};

function formatDuration(intl, seconds) {
  const minutes = Math.round((seconds || 0) / 60);
  if (minutes < 60) return intl.formatMessage({ id: 'duration.minutes' }, { count: minutes });
  return intl.formatMessage({ id: 'duration.hoursMinutes' }, { hours: Math.floor(minutes / 60), minutes: minutes % 60 });
}

function formatTime(locale, iso) {
  if (!iso) return '—';
  const date = new Date(iso);
  return date.toLocaleString(locale, { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
}

function formatCallLength(seconds) {
  const total = Math.max(seconds || 0, 0);
  const minutes = Math.floor(total / 60);
  return `${minutes}:${String(total % 60).padStart(2, '0')}`;
}

// ==============================|| DASHBOARD - OVERVIEW ||============================== //
//
// Two sources on one page: the websocket reports what is happening right now, the
// CDR endpoint reports what already happened. They are kept apart deliberately so
// a stalled socket cannot make the history look wrong, or the reverse.

export default function Overview() {
  const intl = useIntl();
  const [hours, setHours] = useState(24);
  const [direction, setDirection] = useState('');
  const { data, isLoading, error } = useDashboard(hours, direction);
  const { calls, status } = useActiveCalls();

  const totals = data?.totals;
  const unavailable = data && data.available === false;
  const answerRate = totals?.answer_rate ?? null;
  const recent = data?.recent ?? [];
  const statusSeries = Object.entries(data?.statuses ?? {})
    .filter(([, value]) => value > 0)
    .map(([statusName, value], id) => ({
      id,
      value,
      label: intl.formatMessage({ id: `callState.${statusName}` }),
      color: STATUS_CHART_COLOR[statusName]
    }));

  return (
    <Grid container rowSpacing={4.5} columnSpacing={2.75}>
      <Grid sx={{ mb: -2.25 }} size={12}>
        <Stack direction="row" sx={{ alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 1.5 }}>
          <Typography variant="h5">
            <FormattedMessage id="overview.title" />
          </Typography>
          <Stack direction="row" sx={{ flexWrap: 'wrap', gap: 1 }}>
            <ToggleButtonGroup
              size="small"
              exclusive
              value={direction}
              onChange={(event, next) => next !== null && setDirection(next)}
              aria-label={intl.formatMessage({ id: 'table.direction' })}
            >
              <ToggleButton value="" sx={{ textTransform: 'none' }}>
                <FormattedMessage id="history.direction.all" />
              </ToggleButton>
              <ToggleButton value="inbound" sx={{ textTransform: 'none' }}>
                <FormattedMessage id="direction.inbound" />
              </ToggleButton>
              <ToggleButton value="outbound" sx={{ textTransform: 'none' }}>
                <FormattedMessage id="direction.outbound" />
              </ToggleButton>
              <ToggleButton value="local" sx={{ textTransform: 'none' }}>
                <FormattedMessage id="direction.local" />
              </ToggleButton>
            </ToggleButtonGroup>
            <ToggleButtonGroup
              size="small"
              exclusive
              value={hours}
              onChange={(event, next) => next && setHours(next)}
              aria-label={intl.formatMessage({ id: 'overview.title' })}
            >
              {RANGES.map((range) => (
                <ToggleButton key={range.value} value={range.value} sx={{ textTransform: 'none', px: 1.75 }}>
                  <FormattedMessage id={range.labelId} />
                </ToggleButton>
              ))}
            </ToggleButtonGroup>
          </Stack>
        </Stack>
      </Grid>

      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={intl.formatMessage({ id: 'overview.activeCalls' })}
          count={calls.length}
          color={status === 'subscribed' ? 'success' : 'warning'}
          caption={intl.formatMessage({ id: status === 'subscribed' ? 'status.subscribed' : 'status.disconnected' })}
        />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard title={intl.formatMessage({ id: 'overview.inbound' })} count={totals?.inbound ?? '—'} color="primary" />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard title={intl.formatMessage({ id: 'overview.outbound' })} count={totals?.outbound ?? '—'} color="info" />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={intl.formatMessage({ id: 'overview.answerRate' })}
          count={answerRate === null ? '—' : `${answerRate}%`}
          color="success"
        />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard title={intl.formatMessage({ id: 'overview.averageTalk' })} count={formatCallLength(totals?.average_talk_seconds)} />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard title={intl.formatMessage({ id: 'overview.totalCalls' })} count={totals?.calls ?? '—'} />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard
          title={intl.formatMessage({ id: 'overview.answered' })}
          count={totals?.answered ?? '—'}
          color="success"
          caption={answerRate !== null ? `${answerRate}%` : undefined}
        />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard title={intl.formatMessage({ id: 'overview.missed' })} count={totals?.missed ?? '—'} color="error" />
      </Grid>

      <Grid size={{ xs: 12, lg: 8 }}>
        <Typography variant="h5" sx={{ mb: 2 }}>
          <FormattedMessage id="overview.volume" />
        </Typography>
        <MainCard content={false} sx={{ p: 1 }}>
          {unavailable ? (
            <Box sx={{ height: 320, display: 'flex', alignItems: 'center', justifyContent: 'center', px: 3 }}>
              <Typography variant="body2" sx={{ color: 'text.secondary', textAlign: 'center' }}>
                <FormattedMessage id="overview.volume.forbidden" />
              </Typography>
            </Box>
          ) : (
            <CallVolumeChart hourly={data?.hourly ?? []} hours={hours} />
          )}
        </MainCard>
      </Grid>

      <Grid size={{ xs: 12, lg: 4 }}>
        <Typography variant="h5" sx={{ mb: 2 }}>
          <FormattedMessage id="overview.duration" />
        </Typography>
        <MainCard>
          <Stack sx={{ gap: 2.5 }}>
            <Stack sx={{ gap: 0.5 }}>
              <Typography variant="h6" sx={{ color: 'text.secondary' }}>
                <FormattedMessage id="overview.talkTime" />
              </Typography>
              <Typography variant="h3">{formatDuration(intl, totals?.talk_seconds)}</Typography>
            </Stack>
            <Stack direction="row" sx={{ justifyContent: 'space-between' }}>
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                <FormattedMessage id="overview.inbound" />
              </Typography>
              <Typography variant="subtitle2">{totals?.inbound ?? '—'}</Typography>
            </Stack>
            <Stack direction="row" sx={{ justifyContent: 'space-between' }}>
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                <FormattedMessage id="overview.outbound" />
              </Typography>
              <Typography variant="subtitle2">{totals?.outbound ?? '—'}</Typography>
            </Stack>
            <Stack direction="row" sx={{ justifyContent: 'space-between' }}>
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                <FormattedMessage id="overview.unconnected" />
              </Typography>
              <Typography variant="subtitle2">{totals?.unconnected ?? '—'}</Typography>
            </Stack>
            {data?.scope === 'extensions' && (
              <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                <FormattedMessage id="overview.scopeNote" />
              </Typography>
            )}
          </Stack>
        </MainCard>
      </Grid>

      <Grid size={{ xs: 12, lg: 4 }}>
        <Typography variant="h5" sx={{ mb: 2 }}>
          <FormattedMessage id="overview.statusDistribution" />
        </Typography>
        <MainCard>
          {statusSeries.length > 0 ? (
            <PieChart
              height={250}
              series={[{ data: statusSeries, innerRadius: 55, outerRadius: 90, paddingAngle: 2 }]}
              slotProps={{ legend: { direction: 'horizontal', position: { vertical: 'bottom', horizontal: 'center' } } }}
            />
          ) : (
            <Box sx={{ height: 250, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <FormattedMessage id="overview.volume.empty" />
            </Box>
          )}
        </MainCard>
      </Grid>

      <Grid size={12}>
        <Typography variant="h5" sx={{ mb: 2 }}>
          <FormattedMessage id="overview.recent" />
        </Typography>
        <MainCard content={false}>
          <TableContainer sx={{ overflowX: 'auto' }}>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>
                    <FormattedMessage id="table.time" />
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
                </TableRow>
              </TableHead>
              <TableBody>
                {recent.map((row) => (
                  <TableRow key={row.uuid} hover>
                    <TableCell>
                      <Typography variant="body2">{formatTime(intl.locale, row.start_stamp)}</Typography>
                    </TableCell>
                    <TableCell>
                      <Stack>
                        <Typography variant="subtitle2">{row.caller_id_name || '—'}</Typography>
                        <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                          {row.caller_id_number || ''}
                        </Typography>
                      </Stack>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">{row.destination_number || '—'}</Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        variant="combined"
                        color={STATUS_COLOR[row.status] ?? 'secondary'}
                        label={intl.formatMessage({ id: `callState.${row.status}`, defaultMessage: row.status })}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2" sx={{ fontVariantNumeric: 'tabular-nums' }}>
                        {formatCallLength(row.billsec)}
                      </Typography>
                    </TableCell>
                  </TableRow>
                ))}
                {recent.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} align="center" sx={{ py: 6 }}>
                      <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                        <FormattedMessage id={isLoading ? 'table.loading' : error ? 'table.error' : 'table.empty'} />
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
