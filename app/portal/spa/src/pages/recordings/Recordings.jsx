import { useState } from 'react';

import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import Grid from '@mui/material/Grid';
import IconButton from '@mui/material/IconButton';
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
import PlayCircleOutlined from '@ant-design/icons/PlayCircleOutlined';
import { BarChart } from '@mui/x-charts/BarChart';
import { LineChart } from '@mui/x-charts/LineChart';
import { FormattedMessage, useIntl } from 'react-intl';

import MainCard from 'components/MainCard';
import StatCard from 'components/cards/statistics/StatCard';
import ContentState from 'components/states/ContentState';
import RecordingPlayer from 'components/recordings/RecordingPlayer';
import useAnalytics from 'hooks/useAnalytics';
import { RECORDINGS_URL } from 'config';

const today = new Date().toISOString().slice(0, 10);
const initialFrom = new Date(Date.now() - 29 * 86400000).toISOString().slice(0, 10);

const duration = (seconds) => `${Math.floor((seconds || 0) / 60)}:${String((seconds || 0) % 60).padStart(2, '0')}`;
const bytes = (value) => (value ? `${(value / 1024 / 1024).toFixed(1)} MB` : '—');

export default function Recordings() {
  const intl = useIntl();
  const [filters, setFilters] = useState({ from: initialFrom, to: today, q: '', page: 1, page_size: 20 });
  const [playing, setPlaying] = useState(null);
  const { data, error, isLoading, refresh } = useAnalytics(RECORDINGS_URL, filters);
  const update = (key) => (event) => setFilters((current) => ({ ...current, [key]: event.target.value, page: 1 }));
  const rows = data?.rows ?? [];

  return (
    <Grid container spacing={2.75}>
      <Grid size={12}>
        <Typography variant="h5">
          <FormattedMessage id="recordings.title" />
        </Typography>
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard title={intl.formatMessage({ id: 'recordings.count' })} count={data?.totals?.recordings ?? '—'} />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard title={intl.formatMessage({ id: 'recordings.duration' })} count={duration(data?.totals?.duration)} color="primary" />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard title={intl.formatMessage({ id: 'recordings.today' })} count={data?.totals?.today ?? '—'} color="success" />
      </Grid>
      <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
        <StatCard title={intl.formatMessage({ id: 'recordings.transcripts' })} count={data?.totals?.transcripts ?? '—'} color="info" />
      </Grid>

      <Grid size={{ xs: 12, lg: 7 }}>
        <MainCard title={intl.formatMessage({ id: 'recordings.byDay' })}>
          <LineChart
            height={260}
            xAxis={[{ data: (data?.daily ?? []).map((row) => new Date(row.bucket)), scaleType: 'time' }]}
            series={[
              {
                data: (data?.daily ?? []).map((row) => row.recordings),
                label: intl.formatMessage({ id: 'recordings.count' }),
                color: '#1677ff'
              }
            ]}
          />
        </MainCard>
      </Grid>
      <Grid size={{ xs: 12, lg: 5 }}>
        <MainCard title={intl.formatMessage({ id: 'recordings.byExtension' })}>
          <BarChart
            height={260}
            xAxis={[{ scaleType: 'band', data: (data?.by_extension ?? []).map((row) => row.extension) }]}
            series={[
              {
                data: (data?.by_extension ?? []).map((row) => row.duration),
                label: intl.formatMessage({ id: 'recordings.durationSeconds' }),
                color: '#13c2c2'
              }
            ]}
          />
        </MainCard>
      </Grid>

      <Grid size={12}>
        <MainCard title={intl.formatMessage({ id: 'recordings.durationDistribution' })}>
          <BarChart
            height={250}
            xAxis={[
              {
                scaleType: 'band',
                data: (data?.duration_distribution ?? []).map((row) => intl.formatMessage({ id: `recordings.bucket.${row.bucket}` }))
              }
            ]}
            series={[
              {
                data: (data?.duration_distribution ?? []).map((row) => row.recordings),
                label: intl.formatMessage({ id: 'recordings.count' }),
                color: '#722ed1'
              }
            ]}
          />
        </MainCard>
      </Grid>

      <Grid size={12}>
        <MainCard content={false}>
          <Stack direction={{ xs: 'column', md: 'row' }} sx={{ gap: 1.5, p: 2 }}>
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
            <TextField
              size="small"
              label={intl.formatMessage({ id: 'history.search' })}
              value={filters.q}
              onChange={update('q')}
              sx={{ flexGrow: 1 }}
            />
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
            <ContentState state="empty" title={<FormattedMessage id="recordings.empty" />} />
          ) : (
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>
                      <FormattedMessage id="table.time" />
                    </TableCell>
                    <TableCell>
                      <FormattedMessage id="table.extension" />
                    </TableCell>
                    <TableCell>
                      <FormattedMessage id="recordings.remoteParty" />
                    </TableCell>
                    <TableCell>
                      <FormattedMessage id="table.direction" />
                    </TableCell>
                    <TableCell align="right">
                      <FormattedMessage id="table.duration" />
                    </TableCell>
                    <TableCell>
                      <FormattedMessage id="recordings.file" />
                    </TableCell>
                    <TableCell>
                      <FormattedMessage id="recordings.state" />
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
                      <TableCell>{row.extension || '—'}</TableCell>
                      <TableCell>
                        {row.remote_name || row.remote_party || '—'}
                        <Typography variant="caption" display="block" color="text.secondary">
                          {row.remote_party}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <FormattedMessage id={`direction.${row.direction || 'unknown'}`} />
                      </TableCell>
                      <TableCell align="right">{duration(row.duration)}</TableCell>
                      <TableCell>
                        {row.format?.toUpperCase() || '—'} · {bytes(row.file_size)}
                      </TableCell>
                      <TableCell>
                        <Chip
                          size="small"
                          color={row.state === 'available' ? 'success' : 'warning'}
                          label={intl.formatMessage({ id: `recordings.state.${row.state}` })}
                        />
                      </TableCell>
                      <TableCell align="right">
                        <IconButton
                          size="small"
                          disabled={row.state !== 'available' || !data.capabilities?.play}
                          onClick={() => setPlaying(playing === row.uuid ? null : row.uuid)}
                          aria-label={intl.formatMessage({ id: 'recordings.play' })}
                        >
                          <PlayCircleOutlined />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
          {playing && (
            <Box sx={{ p: 2, borderTop: 1, borderColor: 'divider' }}>
              <RecordingPlayer callUuid={playing} allowDownload={Boolean(data?.capabilities?.download)} />
            </Box>
          )}
          {(data?.pages ?? 0) > 1 && (
            <Stack sx={{ alignItems: 'center', p: 2 }}>
              <Pagination page={data.page} count={data.pages} onChange={(event, page) => setFilters((current) => ({ ...current, page }))} />
            </Stack>
          )}
        </MainCard>
      </Grid>
    </Grid>
  );
}
