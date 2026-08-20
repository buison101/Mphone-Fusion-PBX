import { useState } from 'react';

import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Grid from '@mui/material/Grid';
import Pagination from '@mui/material/Pagination';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import TextField from '@mui/material/TextField';
import Typography from '@mui/material/Typography';
import { BarChart } from '@mui/x-charts/BarChart';
import { LineChart } from '@mui/x-charts/LineChart';
import { FormattedMessage, useIntl } from 'react-intl';

import MainCard from 'components/MainCard';
import StatCard from 'components/cards/statistics/StatCard';
import ContentState from 'components/states/ContentState';
import useAnalytics from 'hooks/useAnalytics';
import useSession from 'hooks/useSession';
import { CLICK_TO_CALL_URL, MISSED_CALLS_URL } from 'config';

const today = new Date().toISOString().slice(0, 10);
const initialFrom = new Date(Date.now() - 29 * 86400000).toISOString().slice(0, 10);
const duration = (seconds) => `${Math.floor((seconds || 0) / 60)}:${String((seconds || 0) % 60).padStart(2, '0')}`;

export default function MissedCalls() {
  const intl = useIntl();
  const { session, can } = useSession();
  const [filters, setFilters] = useState({ from: initialFrom, to: today, page: 1, page_size: 20 });
  const [message, setMessage] = useState('');
  const { data, error, isLoading, refresh } = useAnalytics(MISSED_CALLS_URL, filters);
  const rows = data?.rows ?? [];
  const update = (key) => (event) => setFilters((current) => ({ ...current, [key]: event.target.value, page: 1 }));
  const callBack = async (row) => {
    const response = await fetch(CLICK_TO_CALL_URL, {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session.csrf },
      body: JSON.stringify({ extension_uuid: row.extension_uuid, destination: row.caller_number })
    });
    setMessage(intl.formatMessage({ id: response.ok ? 'clickToCall.accepted' : 'clickToCall.failed' }));
  };

  return (
    <Stack sx={{ gap: 2.5 }}>
      <Typography variant="h5">
        <FormattedMessage id="missed.title" />
      </Typography>
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, sm: 3 }}>
          <StatCard title={intl.formatMessage({ id: 'missed.open' })} count={data?.kpis?.open ?? '—'} color="warning" />
        </Grid>
        <Grid size={{ xs: 12, sm: 3 }}>
          <StatCard title={intl.formatMessage({ id: 'missed.calledBack' })} count={data?.kpis?.called_back ?? '—'} color="primary" />
        </Grid>
        <Grid size={{ xs: 12, sm: 3 }}>
          <StatCard title={intl.formatMessage({ id: 'missed.resolved' })} count={data?.kpis?.resolved ?? '—'} color="success" />
        </Grid>
        <Grid size={{ xs: 12, sm: 3 }}>
          <StatCard title={intl.formatMessage({ id: 'missed.overdue' })} count={data?.kpis?.overdue ?? '—'} color="error" />
        </Grid>
      </Grid>
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, lg: 7 }}>
          <MainCard title={intl.formatMessage({ id: 'missed.byDay' })}>
            <LineChart
              height={250}
              xAxis={[{ scaleType: 'time', data: (data?.daily ?? []).map((row) => new Date(row.bucket)) }]}
              series={[
                {
                  data: (data?.daily ?? []).map((row) => row.calls),
                  label: intl.formatMessage({ id: 'overview.missed' }),
                  color: '#ff4d4f'
                }
              ]}
            />
          </MainCard>
        </Grid>
        <Grid size={{ xs: 12, lg: 5 }}>
          <MainCard title={intl.formatMessage({ id: 'missed.byHour' })}>
            <BarChart
              height={250}
              xAxis={[{ scaleType: 'band', data: (data?.hourly ?? []).map((row) => row.hour) }]}
              series={[{ data: (data?.hourly ?? []).map((row) => row.calls), color: '#1677ff' }]}
            />
          </MainCard>
        </Grid>
      </Grid>
      <MainCard content={false}>
        <Stack direction={{ xs: 'column', sm: 'row' }} sx={{ gap: 1.5, p: 2 }}>
          <TextField
            size="small"
            type="date"
            label={intl.formatMessage({ id: 'filter.from' })}
            value={filters.from}
            onChange={update('from')}
            slotProps={{ inputLabel: { shrink: true } }}
          />
          <TextField
            size="small"
            type="date"
            label={intl.formatMessage({ id: 'filter.to' })}
            value={filters.to}
            onChange={update('to')}
            slotProps={{ inputLabel: { shrink: true } }}
          />
          {message && (
            <Typography variant="body2" color="text.secondary">
              {message}
            </Typography>
          )}
        </Stack>
        {isLoading && !data ? (
          <ContentState state="loading" title={<FormattedMessage id="table.loading" />} />
        ) : error ? (
          <ContentState
            state="error"
            title={<FormattedMessage id="table.error" />}
            actionLabel={<FormattedMessage id="action.retry" />}
            onAction={refresh}
          />
        ) : rows.length === 0 ? (
          <ContentState state="empty" title={<FormattedMessage id="missed.empty" />} />
        ) : (
          <TableContainer>
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
                    <FormattedMessage id="table.extension" />
                  </TableCell>
                  <TableCell align="right">
                    <FormattedMessage id="missed.attempts" />
                  </TableCell>
                  <TableCell>
                    <FormattedMessage id="missed.callback" />
                  </TableCell>
                  <TableCell>
                    <FormattedMessage id="table.state" />
                  </TableCell>
                  <TableCell align="right">
                    <FormattedMessage id="table.actions" />
                  </TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((row) => (
                  <TableRow key={row.uuid} hover>
                    <TableCell>{new Date(row.start_stamp).toLocaleString(intl.locale)}</TableCell>
                    <TableCell>
                      {row.caller_name || row.caller_number}
                      <Typography variant="caption" display="block" color="text.secondary">
                        {row.caller_number}
                      </Typography>
                    </TableCell>
                    <TableCell>{row.extension || '—'}</TableCell>
                    <TableCell align="right">{row.attempts}</TableCell>
                    <TableCell>
                      {row.callback_stamp
                        ? `${new Date(row.callback_stamp).toLocaleString(intl.locale)} · ${duration(row.callback_seconds)}`
                        : '—'}
                    </TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        color={
                          row.overdue ? 'error' : row.state === 'resolved' ? 'success' : row.state === 'called_back' ? 'primary' : 'warning'
                        }
                        label={intl.formatMessage({ id: `missed.state.${row.state}` })}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Button size="small" disabled={!can('click_to_call_call')} onClick={() => callBack(row)}>
                        <FormattedMessage id="missed.callBack" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
        {(data?.pages ?? 0) > 1 && (
          <Stack sx={{ alignItems: 'center', p: 2 }}>
            <Pagination page={data.page} count={data.pages} onChange={(event, page) => setFilters((current) => ({ ...current, page }))} />
          </Stack>
        )}
      </MainCard>
      <MainCard title={intl.formatMessage({ id: 'reports.definitions' })}>
        <Typography variant="body2">
          <FormattedMessage id="missed.definition" />
        </Typography>
        <Typography variant="body2">
          <FormattedMessage id="missed.averageCallback" values={{ value: duration(data?.kpis?.average_callback_seconds) }} />
        </Typography>
      </MainCard>
    </Stack>
  );
}
