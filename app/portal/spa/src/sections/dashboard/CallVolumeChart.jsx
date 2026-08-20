import PropTypes from 'prop-types';

// material-ui
import { useTheme, useColorScheme } from '@mui/material/styles';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

// third-party
import { BarChart } from '@mui/x-charts/BarChart';
import { FormattedMessage, useIntl } from 'react-intl';

// ==============================|| DASHBOARD - CALL VOLUME ||============================== //
//
// Answered and missed calls per hour, side by side rather than stacked: the two
// bars carry their own rounded cap and the band gap does the separating, which a
// stacked pair cannot do without a gap between segments.
//
// Three series, because answered and missed alone hide the calls that never
// connected at all: on real data those outnumber both.
//
// Both palettes were checked against their own paper colour, #ffffff and
// #121212. Green for answered reads as the obvious choice and fails colour
// vision deficiency separation against red. Orange fails beside red as well
// (normal-vision ΔE 14). Purple passes cleanly in both modes.
//
// The dark marks are not the palette's error.main and purple main. Those steps
// (#a61d24, #642ab5) are drawn to sit under text on a chip or a button; as a
// filled shape on the page they fall outside the lightness band and reach only
// 2.5:1 against the surface. A chart mark has a different job, so it takes the
// step from the same Ant Design dark ramp that passes: redDark[5], purpleDark[6].

const SERIES_COLOR = {
  light: { answered: '#1677ff', missed: '#ff4d4f', unconnected: '#722ed1' },
  dark: { answered: '#1668dc', missed: '#d32029', unconnected: '#854eca' }
};

function formatHour(iso) {
  const date = new Date(iso);
  return `${String(date.getHours()).padStart(2, '0')}:00`;
}

function formatDay(iso) {
  const date = new Date(iso);
  return `${date.getDate()}/${date.getMonth() + 1}`;
}

export default function CallVolumeChart({ hourly = [], hours = 24 }) {
  const theme = useTheme();
  const { mode, systemMode } = useColorScheme();
  const resolved = (mode === 'system' ? systemMode : mode) === 'dark' ? 'dark' : 'light';
  const series = SERIES_COLOR[resolved];
  const intl = useIntl();
  const answeredLabel = intl.formatMessage({ id: 'chart.answered' });
  const missedLabel = intl.formatMessage({ id: 'chart.missed' });
  const unconnectedLabel = intl.formatMessage({ id: 'chart.unconnected' });
  const label = hours > 48 ? formatDay : formatHour;

  if (hourly.length === 0) {
    return (
      <Box sx={{ height: 320, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Typography variant="body2" sx={{ color: 'text.secondary' }}>
          <FormattedMessage id="overview.volume.empty" />
        </Typography>
      </Box>
    );
  }

  return (
    <BarChart
      height={320}
      borderRadius={4}
      grid={{ horizontal: true }}
      xAxis={[
        {
          scaleType: 'band',
          data: hourly.map((row) => label(row.bucket)),
          categoryGapRatio: 0.45,
          barGapRatio: 0.15,
          tickLabelStyle: { fill: theme.vars.palette.text.secondary, fontSize: 12 }
        }
      ]}
      yAxis={[
        {
          tickLabelStyle: { fill: theme.vars.palette.text.secondary, fontSize: 12 },
          // whole calls only, a fractional tick would be meaningless
          tickMinStep: 1
        }
      ]}
      series={[
        { data: hourly.map((row) => row.answered), label: answeredLabel, color: series.answered },
        { data: hourly.map((row) => row.missed), label: missedLabel, color: series.missed },
        { data: hourly.map((row) => row.unconnected ?? 0), label: unconnectedLabel, color: series.unconnected }
      ]}
      slotProps={{
        legend: {
          direction: 'horizontal',
          position: { vertical: 'top', horizontal: 'end' },
          labelStyle: { fontSize: 12, fill: theme.vars.palette.text.secondary }
        }
      }}
      margin={{ left: 8, right: 8, top: 32, bottom: 8 }}
      sx={{
        // recessive grid and axis, the bars are the only thing allowed to be loud
        '& .MuiChartsGrid-line': { stroke: theme.vars.palette.divider, strokeDasharray: 'none' },
        '& .MuiChartsAxis-line, & .MuiChartsAxis-tick': { stroke: theme.vars.palette.divider }
      }}
    />
  );
}

CallVolumeChart.propTypes = {
  hourly: PropTypes.array,
  hours: PropTypes.number
};
