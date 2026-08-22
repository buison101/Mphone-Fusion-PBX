import { useMemo, useState } from 'react';
import PropTypes from 'prop-types';

import Box from '@mui/material/Box';
import Grid from '@mui/material/Grid';
import Stack from '@mui/material/Stack';
import Tab from '@mui/material/Tab';
import Tabs from '@mui/material/Tabs';
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
import { REPORTS_URL } from 'config';

const reports = ['volume', 'extensions', 'inbound', 'outbound', 'time', 'dimensions'];
const today = new Date().toISOString().slice(0, 10);
const initialFrom = new Date(Date.now() - 29 * 86400000).toISOString().slice(0, 10);
const seconds = (value) => `${Math.floor((value || 0) / 60)}:${String((value || 0) % 60).padStart(2, '0')}`;

function SimpleTable({ columns, rows }) {
  return (
    <TableContainer>
      <Table size="small">
        <TableHead>
          <TableRow>
            {columns.map((column) => (
              <TableCell key={column.key} align={column.numeric ? 'right' : 'left'}>
                <FormattedMessage id={column.label} />
              </TableCell>
            ))}
          </TableRow>
        </TableHead>
        <TableBody>
          {rows.map((row, index) => (
            <TableRow key={row.uuid || row.extension_uuid || row.number || row.did || row.bucket || index} hover>
              {columns.map((column) => (
                <TableCell key={column.key} align={column.numeric ? 'right' : 'left'}>
                  {column.format ? column.format(row[column.key], row) : (row[column.key] ?? '—')}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
}

function Definitions({ definitions, payload }) {
  const intl = useIntl();
  if (!definitions || Object.keys(definitions).length === 0) return null;
  return (
    <MainCard title={intl.formatMessage({ id: 'reports.definitions' })}>
      <Stack sx={{ gap: 0.75 }}>
        {Object.keys(definitions).map((key) => (
          <Typography key={key} variant="body2">
            <Box component="span" sx={{ fontWeight: 600 }}>
              {intl.formatMessage({ id: `metric.name.${key}` })}:
            </Box>{' '}
            {intl.formatMessage(
              { id: `metric.definition.${key}` },
              { seconds: payload?.totals?.success_seconds ?? payload?.totals?.sla_seconds ?? 0 }
            )}
          </Typography>
        ))}
      </Stack>
    </MainCard>
  );
}

SimpleTable.propTypes = {
  columns: PropTypes.arrayOf(
    PropTypes.shape({
      key: PropTypes.string.isRequired,
      label: PropTypes.string.isRequired,
      numeric: PropTypes.bool,
      format: PropTypes.func
    })
  ).isRequired,
  rows: PropTypes.arrayOf(PropTypes.object).isRequired
};

Definitions.propTypes = { definitions: PropTypes.object, payload: PropTypes.oneOfType([PropTypes.object, PropTypes.array]) };

export default function Reports() {
  const intl = useIntl();
  const [report, setReport] = useState('volume');
  const [filters, setFilters] = useState({ from: initialFrom, to: today });
  const { data, error, isLoading, refresh } = useAnalytics(REPORTS_URL, { ...filters, report });
  const update = (key) => (event) => setFilters((current) => ({ ...current, [key]: event.target.value }));
  const payload = data?.data;

  const heatmap = useMemo(() => {
    if (report !== 'time' || !Array.isArray(payload)) return [];
    const map = new Map(payload.map((row) => [`${row.weekday}-${row.hour}`, row]));
    return Array.from({ length: 7 }, (_, day) => Array.from({ length: 24 }, (_, hour) => map.get(`${day + 1}-${hour}`) ?? { total: 0 }));
  }, [report, payload]);

  const renderReport = () => {
    if (report === 'volume') {
      const rows = payload ?? [];
      return (
        <>
          <MainCard title={intl.formatMessage({ id: 'reports.volume' })}>
            <LineChart
              height={320}
              xAxis={[{ data: rows.map((row) => new Date(row.bucket)), scaleType: 'time' }]}
              series={[
                { data: rows.map((row) => row.total), label: intl.formatMessage({ id: 'reports.total' }), color: '#1677ff' },
                { data: rows.map((row) => row.answered), label: intl.formatMessage({ id: 'overview.answered' }), color: '#13c2c2' },
                { data: rows.map((row) => row.missed), label: intl.formatMessage({ id: 'overview.missed' }), color: '#ff4d4f' }
              ]}
            />
          </MainCard>
          <MainCard content={false}>
            <SimpleTable
              rows={rows}
              columns={[
                { key: 'bucket', label: 'table.time', format: (v) => new Date(v).toLocaleDateString(intl.locale) },
                { key: 'total', label: 'reports.total', numeric: true },
                { key: 'inbound', label: 'overview.inbound', numeric: true },
                { key: 'outbound', label: 'overview.outbound', numeric: true },
                { key: 'answered', label: 'overview.answered', numeric: true },
                { key: 'missed', label: 'overview.missed', numeric: true },
                { key: 'answer_rate', label: 'overview.answerRate', numeric: true, format: (v) => (v === null ? '—' : `${v}%`) },
                { key: 'average_talk', label: 'overview.averageTalk', numeric: true, format: seconds }
              ]}
            />
          </MainCard>
        </>
      );
    }
    if (report === 'extensions') {
      const rows = payload ?? [];
      return (
        <>
          <MainCard title={intl.formatMessage({ id: 'reports.topExtensions' })}>
            <BarChart
              height={300}
              xAxis={[{ scaleType: 'band', data: rows.slice(0, 12).map((row) => row.extension) }]}
              series={[
                { data: rows.slice(0, 12).map((row) => row.total), label: intl.formatMessage({ id: 'reports.total' }), color: '#1677ff' },
                {
                  data: rows.slice(0, 12).map((row) => row.talk_seconds),
                  label: intl.formatMessage({ id: 'reports.talkSeconds' }),
                  color: '#13c2c2'
                }
              ]}
            />
          </MainCard>
          <MainCard content={false}>
            <SimpleTable
              rows={rows}
              columns={[
                { key: 'extension', label: 'table.extension' },
                { key: 'total', label: 'reports.total', numeric: true },
                { key: 'inbound', label: 'overview.inbound', numeric: true },
                { key: 'answered', label: 'overview.answered', numeric: true },
                { key: 'missed', label: 'overview.missed', numeric: true },
                { key: 'outbound', label: 'overview.outbound', numeric: true },
                { key: 'talk_seconds', label: 'reports.talkTime', numeric: true, format: seconds },
                { key: 'answer_rate', label: 'overview.answerRate', numeric: true, format: (v) => (v === null ? '—' : `${v}%`) }
              ]}
            />
          </MainCard>
        </>
      );
    }
    if (report === 'inbound') {
      const totals = payload?.totals ?? {};
      return (
        <>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, sm: 3 }}>
              <StatCard title={intl.formatMessage({ id: 'reports.totalInbound' })} count={totals.total ?? '—'} />
            </Grid>
            <Grid size={{ xs: 12, sm: 3 }}>
              <StatCard
                title={intl.formatMessage({ id: 'overview.answerRate' })}
                count={totals.answer_rate == null ? '—' : `${totals.answer_rate}%`}
                color="success"
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 3 }}>
              <StatCard title={intl.formatMessage({ id: 'reports.averageWait' })} count={seconds(totals.average_wait)} />
            </Grid>
            <Grid size={{ xs: 12, sm: 3 }}>
              <StatCard title={intl.formatMessage({ id: 'reports.withinSla' })} count={totals.within_sla ?? '—'} color="primary" />
            </Grid>
          </Grid>
          <MainCard title={intl.formatMessage({ id: 'reports.waitDistribution' })}>
            <BarChart
              height={300}
              xAxis={[{ scaleType: 'band', data: (payload?.buckets ?? []).map((row) => row.bucket) }]}
              series={[
                {
                  data: (payload?.buckets ?? []).map((row) => row.answered),
                  label: intl.formatMessage({ id: 'overview.answered' }),
                  color: '#1677ff'
                },
                {
                  data: (payload?.buckets ?? []).map((row) => row.abandoned),
                  label: intl.formatMessage({ id: 'reports.abandoned' }),
                  color: '#ff4d4f'
                }
              ]}
            />
          </MainCard>
        </>
      );
    }
    if (report === 'outbound') {
      const totals = payload?.totals ?? {};
      return (
        <>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, sm: 3 }}>
              <StatCard title={intl.formatMessage({ id: 'reports.totalOutbound' })} count={totals.total ?? '—'} />
            </Grid>
            <Grid size={{ xs: 12, sm: 3 }}>
              <StatCard title={intl.formatMessage({ id: 'reports.connected' })} count={totals.connected ?? '—'} color="primary" />
            </Grid>
            <Grid size={{ xs: 12, sm: 3 }}>
              <StatCard
                title={intl.formatMessage({ id: 'reports.successRate' })}
                count={totals.success_rate == null ? '—' : `${totals.success_rate}%`}
                color="success"
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 3 }}>
              <StatCard title={intl.formatMessage({ id: 'reports.uniqueNumbers' })} count={totals.unique_numbers ?? '—'} />
            </Grid>
          </Grid>
          <MainCard content={false}>
            <SimpleTable
              rows={payload?.numbers ?? []}
              columns={[
                { key: 'number', label: 'reports.number' },
                { key: 'calls', label: 'reports.total', numeric: true },
                { key: 'connected', label: 'reports.connected', numeric: true },
                { key: 'successful', label: 'reports.successful', numeric: true },
                { key: 'talk_seconds', label: 'reports.talkTime', numeric: true, format: seconds },
                { key: 'latest', label: 'reports.latest', format: (v) => new Date(v).toLocaleString(intl.locale) }
              ]}
            />
          </MainCard>
        </>
      );
    }
    if (report === 'time') {
      const maximum = Math.max(1, ...(payload ?? []).map((row) => row.total));
      return (
        <MainCard title={intl.formatMessage({ id: 'reports.heatmap' })}>
          <Box sx={{ overflowX: 'auto' }}>
            <Box sx={{ display: 'grid', gridTemplateColumns: '52px repeat(24, minmax(24px, 1fr))', gap: '3px', minWidth: 760 }}>
              {Array.from({ length: 24 }, (_, hour) => (
                <Typography key={`h-${hour}`} variant="caption" textAlign="center">
                  {hour}
                </Typography>
              )).reduce((all, item, index) => (index === 0 ? [<Box key="corner" />, item] : [...all, item]), [])}
              {heatmap.flatMap((day, dayIndex) => [
                <Typography key={`d-${dayIndex}`} variant="caption">
                  {intl.formatMessage({ id: `weekday.${dayIndex + 1}` })}
                </Typography>,
                ...day.map((cell, hour) => (
                  <Box
                    key={`${dayIndex}-${hour}`}
                    title={`${cell.total}`}
                    sx={{ height: 28, borderRadius: 0.5, bgcolor: '#1677ff', opacity: 0.08 + (cell.total / maximum) * 0.92 }}
                  />
                ))
              ])}
            </Box>
          </Box>
        </MainCard>
      );
    }
    const dids = payload?.dids ?? [];
    const groups = payload?.groups ?? [];
    if (dids.length === 0 && groups.length === 0)
      return (
        <ContentState
          state="empty"
          title={<FormattedMessage id="reports.dimensionsEmpty" />}
          detail={<FormattedMessage id="reports.dimensionsEmptyDetail" />}
        />
      );
    return (
      <>
        {dids.length > 0 && (
          <MainCard title="DID" content={false}>
            <SimpleTable
              rows={dids}
              columns={[
                { key: 'did', label: 'reports.did' },
                { key: 'total', label: 'reports.totalInbound', numeric: true },
                { key: 'answered', label: 'overview.answered', numeric: true },
                { key: 'missed', label: 'overview.missed', numeric: true },
                { key: 'answer_rate', label: 'overview.answerRate', numeric: true, format: (v) => `${v}%` },
                { key: 'average_wait', label: 'reports.averageWait', numeric: true, format: seconds }
              ]}
            />
          </MainCard>
        )}
        {groups.length > 0 && (
          <MainCard title={intl.formatMessage({ id: 'reports.queuesAndRings' })} content={false}>
            <SimpleTable
              rows={groups}
              columns={[
                { key: 'name', label: 'reports.name' },
                { key: 'kind', label: 'reports.type' },
                { key: 'total', label: 'reports.totalInbound', numeric: true },
                { key: 'answered', label: 'overview.answered', numeric: true },
                { key: 'missed', label: 'reports.abandoned', numeric: true },
                { key: 'answer_rate', label: 'overview.answerRate', numeric: true, format: (v) => `${v}%` },
                { key: 'average_wait', label: 'reports.averageWait', numeric: true, format: seconds }
              ]}
            />
          </MainCard>
        )}
      </>
    );
  };

  return (
    <Stack sx={{ gap: 2.5 }}>
      <Typography variant="h2">
        <FormattedMessage id="reports.title" />
      </Typography>
      <MainCard content={false}>
        <Tabs value={report} onChange={(event, value) => setReport(value)} variant="scrollable" scrollButtons="auto">
          {reports.map((item) => (
            <Tab key={item} value={item} label={intl.formatMessage({ id: `reports.tab.${item}` })} />
          ))}
        </Tabs>
        <Stack direction={{ xs: 'column', sm: 'row' }} sx={{ gap: 1.5, p: 2, borderTop: 1, borderColor: 'divider' }}>
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
        </Stack>
      </MainCard>
      {isLoading && !data ? (
        <ContentState state="loading" title={<FormattedMessage id="table.loading" />} />
      ) : error ? (
        <ContentState
          state="error"
          title={<FormattedMessage id="table.error" />}
          actionLabel={<FormattedMessage id="action.retry" />}
          onAction={refresh}
        />
      ) : (
        <>
          {renderReport()}
          <Definitions definitions={data?.definitions} payload={payload} />
        </>
      )}
    </Stack>
  );
}
