import { useMemo, useState } from 'react';

// material-ui
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Grid from '@mui/material/Grid';
import IconButton from '@mui/material/IconButton';
import MenuItem from '@mui/material/MenuItem';
import Stack from '@mui/material/Stack';
import Tab from '@mui/material/Tab';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TablePagination from '@mui/material/TablePagination';
import TableRow from '@mui/material/TableRow';
import Tabs from '@mui/material/Tabs';
import TextField from '@mui/material/TextField';
import Tooltip from '@mui/material/Tooltip';
import Typography from '@mui/material/Typography';

// third-party
import { FormattedMessage, useIntl } from 'react-intl';

// project imports
import MainCard from 'components/MainCard';
import ContentState from 'components/states/ContentState';
import CallDetailsDrawer from 'pages/calls/CallDetailsDrawer';
import useCallHistory from 'hooks/useCallHistory';
import useSession from 'hooks/useSession';
import { CALLS_URL, RECORDING_URL, CALL_TAGS_URL } from 'config';
import { CALL_STATUSES, STATUS_COLOR } from 'utils/callStatus';
import { CALL_DIRECTIONS, CALL_PAGE_SIZES, EMPTY_CALL_FILTERS, toCallSearchParams } from 'utils/callFilters';

// assets
import DownloadOutlined from '@ant-design/icons/DownloadOutlined';
import ExportOutlined from '@ant-design/icons/ExportOutlined';
import EyeOutlined from '@ant-design/icons/EyeOutlined';
import PlayCircleOutlined from '@ant-design/icons/PlayCircleOutlined';

const INITIAL_FILTERS = {
  ...EMPTY_CALL_FILTERS,
  extension_uuid: '',
  recording: '',
  wait_max: '',
  talk_min: '',
  tag_uuid: '',
  has_note: '',
  has_transcript: '',
  has_summary: ''
};
const TABS = ['all', 'inbound', 'outbound', 'local', 'missed', 'recording'];

function formatSeconds(seconds) {
  const total = Math.max(Number(seconds) || 0, 0);
  return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, '0')}`;
}

export default function CallHistoryPhase1() {
  const intl = useIntl();
  const { session } = useSession();
  const [filters, setFilters] = useState(INITIAL_FILTERS);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(CALL_PAGE_SIZES[0]);
  const [selectedCall, setSelectedCall] = useState(null);
  const [taggingCall, setTaggingCall] = useState('');
  const [tagActionError, setTagActionError] = useState(false);

  const query = useMemo(() => ({ ...filters, page: page + 1, page_size: pageSize }), [filters, page, pageSize]);
  const { data, isLoading, error, forbidden, refresh } = useCallHistory(query);
  const rows = data?.rows ?? [];
  const total = data?.total ?? 0;
  const showRecording = Boolean(data?.recordings);
  const allowDownload = Boolean(data?.capabilities?.recording_download);
  const allowExport = Boolean(data?.capabilities?.csv_export);
  const showTags = Boolean(session?.permissions?.portal_call_tag_view);
  const extensions = session?.user?.extensions ?? [];
  const tagOptions = data?.tag_options ?? [];
  const tab = filters.recording === 'yes' ? 'recording' : filters.status === 'missed' ? 'missed' : filters.direction || 'all';

  const update = (key) => (event) => {
    setFilters((current) => ({ ...current, [key]: event.target.value }));
    setPage(0);
  };

  const selectTab = (event, value) => {
    setFilters((current) => ({
      ...current,
      direction: CALL_DIRECTIONS.includes(value) ? value : '',
      status: value === 'missed' ? 'missed' : '',
      recording: value === 'recording' ? 'yes' : ''
    }));
    setPage(0);
  };

  const reset = () => {
    setFilters(INITIAL_FILTERS);
    setPage(0);
  };

  const exportUrl = `${CALLS_URL}?${toCallSearchParams({ ...filters, format: 'csv' }).toString()}`;

  const changeCallTag = async (callUuid, tagUuid, action) => {
    if (!session?.csrf || !tagUuid) return;
    setTaggingCall(callUuid);
    setTagActionError(false);
    try {
      const response = await fetch(CALL_TAGS_URL, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session.csrf },
        body: JSON.stringify({ action, call_uuid: callUuid, tag_uuid: tagUuid })
      });
      if (!response.ok) throw new Error('tag_action_failed');
      await refresh();
    } catch {
      setTagActionError(true);
    } finally {
      setTaggingCall('');
    }
  };

  if (forbidden) {
    return <ContentState state="forbidden" title={<FormattedMessage id="history.forbidden" />} />;
  }

  return (
    <Grid container spacing={2.5}>
      <Grid size={12}>
        <Stack direction="row" sx={{ alignItems: 'center', justifyContent: 'space-between', gap: 1.5, flexWrap: 'wrap' }}>
          <Typography variant="h2">
            <FormattedMessage id="history.title" />
          </Typography>
          <Stack direction="row" sx={{ alignItems: 'center', gap: 1.5 }}>
            <Typography variant="body2" sx={{ color: 'text.secondary' }}>
              <FormattedMessage id="history.results" values={{ total }} />
            </Typography>
            {allowExport && (
              <Button component="a" href={exportUrl} variant="outlined" size="small" startIcon={<ExportOutlined />}>
                <FormattedMessage id="history.export" />
              </Button>
            )}
          </Stack>
        </Stack>
      </Grid>

      <Grid size={12}>
        <MainCard content={false}>
          <Tabs value={tab} onChange={selectTab} variant="scrollable" scrollButtons="auto">
            {TABS.map((value) => (
              <Tab key={value} value={value} label={intl.formatMessage({ id: `history.tab.${value}` })} />
            ))}
          </Tabs>
        </MainCard>
      </Grid>

      <Grid size={12}>
        <MainCard contentSX={{ p: 2 }}>
          <Grid container spacing={1.5} sx={{ alignItems: 'center' }}>
            <Grid size={{ xs: 12, md: 3 }}>
              <TextField
                fullWidth
                size="small"
                value={filters.q}
                onChange={update('q')}
                placeholder={intl.formatMessage({ id: 'history.search' })}
              />
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <TextField
                fullWidth
                size="small"
                type="date"
                label={intl.formatMessage({ id: 'history.from' })}
                slotProps={{ inputLabel: { shrink: true } }}
                value={filters.from}
                onChange={update('from')}
              />
            </Grid>
            {extensions.length > 1 && (
              <Grid size={{ xs: 6, md: 2 }}>
                <TextField
                  fullWidth
                  select
                  size="small"
                  value={filters.extension_uuid}
                  onChange={update('extension_uuid')}
                  label={intl.formatMessage({ id: 'table.extension' })}
                >
                  <MenuItem value="">
                    <FormattedMessage id="history.extension.all" />
                  </MenuItem>
                  {extensions.map((extension) => (
                    <MenuItem key={extension.extension_uuid} value={extension.extension_uuid}>
                      {extension.extension}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>
            )}
            <Grid size={{ xs: 6, md: 2 }}>
              <TextField
                fullWidth
                size="small"
                type="number"
                value={filters.wait_max}
                onChange={update('wait_max')}
                label={intl.formatMessage({ id: 'history.waitMax' })}
                slotProps={{ htmlInput: { min: 0, max: 86400 } }}
              />
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <TextField
                fullWidth
                size="small"
                type="number"
                value={filters.talk_min}
                onChange={update('talk_min')}
                label={intl.formatMessage({ id: 'history.talkMin' })}
                slotProps={{ htmlInput: { min: 0, max: 86400 } }}
              />
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <TextField
                fullWidth
                size="small"
                type="date"
                label={intl.formatMessage({ id: 'history.to' })}
                slotProps={{ inputLabel: { shrink: true } }}
                value={filters.to}
                onChange={update('to')}
              />
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <TextField
                fullWidth
                select
                size="small"
                value={filters.direction}
                onChange={update('direction')}
                label={intl.formatMessage({ id: 'table.direction' })}
              >
                <MenuItem value="">
                  <FormattedMessage id="history.direction.all" />
                </MenuItem>
                {CALL_DIRECTIONS.map((value) => (
                  <MenuItem key={value} value={value}>
                    <FormattedMessage id={`direction.${value}`} />
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <TextField
                fullWidth
                select
                size="small"
                value={filters.status}
                onChange={update('status')}
                label={intl.formatMessage({ id: 'table.state' })}
              >
                <MenuItem value="">
                  <FormattedMessage id="history.status.all" />
                </MenuItem>
                {CALL_STATUSES.map((value) => (
                  <MenuItem key={value} value={value}>
                    <FormattedMessage id={`callState.${value}`} />
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
            {session?.permissions?.portal_call_tag_view && (
              <Grid size={{ xs: 6, md: 2 }}>
                <TextField
                  fullWidth
                  select
                  size="small"
                  value={filters.tag_uuid}
                  onChange={update('tag_uuid')}
                  label={intl.formatMessage({ id: 'history.tag' })}
                >
                  <MenuItem value="">
                    <FormattedMessage id="history.tag.all" />
                  </MenuItem>
                  {tagOptions.map((tag) => (
                    <MenuItem key={tag.uuid} value={tag.uuid}>
                      {tag.name}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>
            )}
            {session?.permissions?.portal_call_note_view && (
              <Grid size={{ xs: 6, md: 2 }}>
                <TextField
                  fullWidth
                  select
                  size="small"
                  value={filters.has_note}
                  onChange={update('has_note')}
                  label={intl.formatMessage({ id: 'history.hasNote' })}
                >
                  <MenuItem value="">
                    <FormattedMessage id="history.any" />
                  </MenuItem>
                  <MenuItem value="yes">
                    <FormattedMessage id="history.yes" />
                  </MenuItem>
                  <MenuItem value="no">
                    <FormattedMessage id="history.no" />
                  </MenuItem>
                </TextField>
              </Grid>
            )}
            {session?.permissions?.xml_cdr_transcript_view && (
              <Grid size={{ xs: 6, md: 2 }}>
                <TextField
                  fullWidth
                  select
                  size="small"
                  value={filters.has_transcript}
                  onChange={update('has_transcript')}
                  label={intl.formatMessage({ id: 'history.hasTranscript' })}
                >
                  <MenuItem value="">
                    <FormattedMessage id="history.any" />
                  </MenuItem>
                  <MenuItem value="yes">
                    <FormattedMessage id="history.yes" />
                  </MenuItem>
                  <MenuItem value="no">
                    <FormattedMessage id="history.no" />
                  </MenuItem>
                </TextField>
              </Grid>
            )}
            {session?.permissions?.xml_cdr_transcript_view && (
              <Grid size={{ xs: 6, md: 2 }}>
                <TextField
                  fullWidth
                  select
                  size="small"
                  value={filters.has_summary}
                  onChange={update('has_summary')}
                  label={intl.formatMessage({ id: 'history.hasSummary' })}
                >
                  <MenuItem value="">
                    <FormattedMessage id="history.any" />
                  </MenuItem>
                  <MenuItem value="yes">
                    <FormattedMessage id="history.yes" />
                  </MenuItem>
                  <MenuItem value="no">
                    <FormattedMessage id="history.no" />
                  </MenuItem>
                </TextField>
              </Grid>
            )}
            <Grid size={{ xs: 12, md: 1 }}>
              <Button size="small" onClick={reset}>
                <FormattedMessage id="history.reset" />
              </Button>
            </Grid>
          </Grid>
        </MainCard>
      </Grid>

      <Grid size={12}>
        <MainCard content={false}>
          {tagActionError && (
            <Typography variant="body2" color="error" sx={{ px: 2, pt: 1.5 }}>
              <FormattedMessage id="metadata.error" />
            </Typography>
          )}
          <TableContainer sx={{ overflowX: 'auto' }}>
            <Table size="small" sx={{ minWidth: 980 }}>
              <TableHead>
                <TableRow>
                  <TableCell>
                    <FormattedMessage id="table.time" />
                  </TableCell>
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
                  {showTags && (
                    <TableCell>
                      <FormattedMessage id="metadata.tags" />
                    </TableCell>
                  )}
                  <TableCell align="right">
                    <FormattedMessage id="table.wait" />
                  </TableCell>
                  <TableCell align="right">
                    <FormattedMessage id="table.talk" />
                  </TableCell>
                  {showRecording && (
                    <TableCell align="right">
                      <FormattedMessage id="history.recording" />
                    </TableCell>
                  )}
                  <TableCell align="right">
                    <FormattedMessage id="table.actions" />
                  </TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((row) => (
                  <TableRow key={row.uuid} hover>
                    <TableCell>{row.start_stamp ? new Date(row.start_stamp).toLocaleString(intl.locale) : '—'}</TableCell>
                    <TableCell>
                      <FormattedMessage id={`direction.${row.direction || 'unknown'}`} />
                    </TableCell>
                    <TableCell>
                      <Stack>
                        <Typography variant="subtitle2">{row.caller_id_name || '—'}</Typography>
                        <Typography variant="caption" color="text.secondary">
                          {row.caller_id_number}
                        </Typography>
                      </Stack>
                    </TableCell>
                    <TableCell>{row.destination_number || '—'}</TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        variant="combined"
                        color={STATUS_COLOR[row.status] ?? 'secondary'}
                        label={intl.formatMessage({ id: `callState.${row.status}`, defaultMessage: row.status })}
                      />
                    </TableCell>
                    {showTags && (
                      <TableCell>
                        <Stack sx={{ gap: 0.75, minWidth: 150 }}>
                          <Stack direction="row" sx={{ gap: 0.5, flexWrap: 'wrap' }}>
                            {(row.tags || []).slice(0, 3).map((tag) => (
                              <Chip
                                key={tag.uuid}
                                size="small"
                                color={tag.color || 'primary'}
                                label={tag.name}
                                onDelete={
                                  session?.permissions?.portal_call_tag_assign && taggingCall !== row.uuid
                                    ? () => changeCallTag(row.uuid, tag.uuid, 'unassign')
                                    : undefined
                                }
                              />
                            ))}
                          </Stack>
                          {session?.permissions?.portal_call_tag_assign && (
                            <TextField
                              select
                              size="small"
                              value=""
                              disabled={
                                taggingCall === row.uuid ||
                                tagOptions.every((tag) => (row.tags || []).some((assigned) => assigned.uuid === tag.uuid))
                              }
                              onChange={(event) => changeCallTag(row.uuid, event.target.value, 'assign')}
                              slotProps={{ select: { displayEmpty: true } }}
                            >
                              <MenuItem value="" disabled>
                                <FormattedMessage id="metadata.selectTag" />
                              </MenuItem>
                              {tagOptions
                                .filter((tag) => !(row.tags || []).some((assigned) => assigned.uuid === tag.uuid))
                                .map((tag) => (
                                  <MenuItem key={tag.uuid} value={tag.uuid}>
                                    {tag.name}
                                  </MenuItem>
                                ))}
                            </TextField>
                          )}
                        </Stack>
                      </TableCell>
                    )}
                    <TableCell align="right" sx={{ fontVariantNumeric: 'tabular-nums' }}>
                      {formatSeconds(row.waitsec)}
                    </TableCell>
                    <TableCell align="right" sx={{ fontVariantNumeric: 'tabular-nums' }}>
                      {formatSeconds(row.billsec)}
                    </TableCell>
                    {showRecording && (
                      <TableCell align="right">
                        {row.recording ? (
                          <Stack direction="row" justifyContent="flex-end">
                            <Tooltip title={intl.formatMessage({ id: 'history.play' })}>
                              <IconButton size="small" onClick={() => setSelectedCall(row)}>
                                <PlayCircleOutlined />
                              </IconButton>
                            </Tooltip>
                            {allowDownload && (
                              <Tooltip title={intl.formatMessage({ id: 'history.download' })}>
                                <IconButton size="small" component="a" href={`${RECORDING_URL}?id=${row.uuid}&download=1`}>
                                  <DownloadOutlined />
                                </IconButton>
                              </Tooltip>
                            )}
                          </Stack>
                        ) : (
                          '—'
                        )}
                      </TableCell>
                    )}
                    <TableCell align="right">
                      <Tooltip title={intl.formatMessage({ id: 'details.title' })}>
                        <IconButton size="small" onClick={() => setSelectedCall(row)}>
                          <EyeOutlined />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
          {rows.length === 0 && (
            <ContentState
              compact
              state={isLoading ? 'loading' : error ? 'error' : 'empty'}
              title={<FormattedMessage id={isLoading ? 'table.loading' : error ? 'table.error' : 'table.empty'} />}
            />
          )}
          <TablePagination
            component="div"
            count={total}
            page={page}
            onPageChange={(event, value) => setPage(value)}
            rowsPerPage={pageSize}
            onRowsPerPageChange={(event) => {
              setPageSize(Number(event.target.value));
              setPage(0);
            }}
            rowsPerPageOptions={CALL_PAGE_SIZES}
            labelRowsPerPage={intl.formatMessage({ id: 'history.rowsPerPage' })}
          />
        </MainCard>
      </Grid>
      <CallDetailsDrawer
        call={selectedCall}
        onClose={() => setSelectedCall(null)}
        allowDownload={allowDownload}
        allowSummaryRetry={Boolean(session?.permissions?.transcribe_queue_edit)}
        csrf={session?.csrf || ''}
      />
    </Grid>
  );
}
