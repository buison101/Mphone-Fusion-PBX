import { useMemo, useState } from 'react';

// material-ui
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import Grid from '@mui/material/Grid';
import IconButton from '@mui/material/IconButton';
import MenuItem from '@mui/material/MenuItem';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TablePagination from '@mui/material/TablePagination';
import TableRow from '@mui/material/TableRow';
import TextField from '@mui/material/TextField';
import Tooltip from '@mui/material/Tooltip';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';

// third-party
import { FormattedMessage, useIntl } from 'react-intl';

// project imports
import MainCard from 'components/MainCard';
import useCallHistory from 'hooks/useCallHistory';
import { CALL_STATUSES, STATUS_COLOR } from 'utils/callStatus';
import { CALL_DIRECTIONS, CALL_PAGE_SIZES, EMPTY_CALL_FILTERS } from 'utils/callFilters';
import { RECORDING_URL } from 'config';

// assets
import PlayCircleOutlined from '@ant-design/icons/PlayCircleOutlined';
import DownloadOutlined from '@ant-design/icons/DownloadOutlined';

function formatLength(seconds) {
  const total = Math.max(seconds || 0, 0);
  return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, '0')}`;
}

// ==============================|| CALLS - HISTORY ||============================== //
//
// Paging and filtering are server side. The customer may hold tens of thousands
// of records and the browser is never asked to hold them all to filter locally.

export default function CallHistory() {
  const intl = useIntl();
  const [filters, setFilters] = useState(EMPTY_CALL_FILTERS);
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(CALL_PAGE_SIZES[0]);
  const [playing, setPlaying] = useState(null);

  const query = useMemo(() => ({ ...filters, page: page + 1, page_size: pageSize }), [filters, page, pageSize]);
  const { data, isLoading, error, forbidden } = useCallHistory(query);

  const rows = data?.rows ?? [];
  const total = data?.total ?? 0;
  const showRecording = Boolean(data?.recordings);

  // any filter change invalidates the current page number
  const update = (key) => (event) => {
    setFilters((current) => ({ ...current, [key]: event.target.value }));
    setPage(0);
  };

  const reset = () => {
    setFilters(EMPTY_CALL_FILTERS);
    setPage(0);
  };

  if (forbidden) {
    return (
      <MainCard>
        <Box sx={{ py: 6, textAlign: 'center' }}>
          <Typography variant="body2" sx={{ color: 'text.secondary' }}>
            <FormattedMessage id="history.forbidden" />
          </Typography>
        </Box>
      </MainCard>
    );
  }

  return (
    <Grid container spacing={2.5}>
      <Grid size={12}>
        <Stack direction="row" sx={{ alignItems: 'center', justifyContent: 'flex-end', flexWrap: 'wrap', gap: 1.5 }}>
          <Typography variant="body2" sx={{ color: 'text.secondary' }}>
            <FormattedMessage id="history.results" values={{ total }} />
          </Typography>
        </Stack>
      </Grid>

      {/* filters sit in one row above the table, never inside it */}
      <Grid size={12}>
        <MainCard contentSX={{ p: 2 }}>
          <Grid container spacing={2} sx={{ alignItems: 'center' }}>
            <Grid size={{ xs: 12, md: 4, lg: 3 }}>
              <TextField
                fullWidth
                size="small"
                value={filters.q}
                onChange={update('q')}
                placeholder={intl.formatMessage({ id: 'history.search' })}
                inputProps={{ 'aria-label': intl.formatMessage({ id: 'history.search' }) }}
              />
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <TextField
                fullWidth
                size="small"
                type="date"
                label={intl.formatMessage({ id: 'history.from' })}
                InputLabelProps={{ shrink: true }}
                value={filters.from}
                onChange={update('from')}
              />
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <TextField
                fullWidth
                size="small"
                type="date"
                label={intl.formatMessage({ id: 'history.to' })}
                InputLabelProps={{ shrink: true }}
                value={filters.to}
                onChange={update('to')}
              />
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <TextField fullWidth select size="small" value={filters.direction} onChange={update('direction')}>
                <MenuItem value="">
                  <FormattedMessage id="history.direction.all" />
                </MenuItem>
                {CALL_DIRECTIONS.map((direction) => (
                  <MenuItem key={direction} value={direction}>
                    <FormattedMessage id={`direction.${direction}`} />
                  </MenuItem>
                ))}
              </TextField>
            </Grid>
            <Grid size={{ xs: 6, md: 2 }}>
              <TextField fullWidth select size="small" value={filters.status} onChange={update('status')}>
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
            <Grid size={{ xs: 12, md: 'auto' }}>
              <Button size="small" onClick={reset} sx={{ textTransform: 'none' }}>
                <FormattedMessage id="history.reset" />
              </Button>
            </Grid>
          </Grid>
        </MainCard>
      </Grid>

      <Grid size={12}>
        <MainCard content={false}>
          <TableContainer sx={{ overflowX: 'auto' }}>
            <Table size="small">
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
                  <TableCell align="right">
                    <FormattedMessage id="table.duration" />
                  </TableCell>
                  {showRecording && (
                    <TableCell align="right">
                      <FormattedMessage id="history.recording" />
                    </TableCell>
                  )}
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((row) => (
                  <TableRow key={row.uuid} hover>
                    <TableCell>
                      <Typography variant="body2">
                        {row.start_stamp ? new Date(row.start_stamp).toLocaleString(intl.locale) : '—'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        <FormattedMessage id={`direction.${row.direction || 'unknown'}`} defaultMessage="—" />
                      </Typography>
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
                        {formatLength(row.billsec)}
                      </Typography>
                    </TableCell>
                    {showRecording && (
                      <TableCell align="right">
                        {row.recording ? (
                          <Stack direction="row" sx={{ justifyContent: 'flex-end', alignItems: 'center', gap: 0.5 }}>
                            {playing === row.uuid ? (
                              <Box
                                component="audio"
                                controls
                                autoPlay
                                preload="none"
                                src={`${RECORDING_URL}?id=${row.uuid}`}
                                sx={{ height: 32, maxWidth: 220 }}
                              />
                            ) : (
                              <Tooltip title={intl.formatMessage({ id: 'history.play' })}>
                                <IconButton size="small" onClick={() => setPlaying(row.uuid)} aria-label="play">
                                  <PlayCircleOutlined />
                                </IconButton>
                              </Tooltip>
                            )}
                            <Tooltip title={intl.formatMessage({ id: 'history.download' })}>
                              <IconButton
                                size="small"
                                component="a"
                                href={`${RECORDING_URL}?id=${row.uuid}&download=1`}
                                aria-label="download"
                              >
                                <DownloadOutlined />
                              </IconButton>
                            </Tooltip>
                          </Stack>
                        ) : (
                          <Typography variant="caption" sx={{ color: 'text.disabled' }}>
                            —
                          </Typography>
                        )}
                      </TableCell>
                    )}
                  </TableRow>
                ))}
                {rows.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={showRecording ? 7 : 6} align="center" sx={{ py: 6 }}>
                      <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                        <FormattedMessage id={isLoading ? 'table.loading' : error ? 'table.error' : 'table.empty'} />
                      </Typography>
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
          <TablePagination
            component="div"
            count={total}
            page={page}
            onPageChange={(event, next) => setPage(next)}
            rowsPerPage={pageSize}
            onRowsPerPageChange={(event) => {
              setPageSize(parseInt(event.target.value, 10));
              setPage(0);
            }}
            rowsPerPageOptions={CALL_PAGE_SIZES}
            labelRowsPerPage={intl.formatMessage({ id: 'history.rowsPerPage' })}
          />
        </MainCard>
      </Grid>
    </Grid>
  );
}
