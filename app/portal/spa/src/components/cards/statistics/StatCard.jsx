import PropTypes from 'prop-types';

// material-ui
import Chip from '@mui/material/Chip';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

// project imports
import MainCard from 'components/MainCard';

// ==============================|| STATISTICS - STAT CARD ||============================== //

export default function StatCard({ title, count, color = 'primary', caption }) {
  return (
    <MainCard contentSX={{ p: 2.25 }}>
      <Stack sx={{ gap: 0.5 }}>
        <Typography variant="h6" sx={{ color: 'text.secondary' }}>
          {title}
        </Typography>
        <Stack direction="row" sx={{ alignItems: 'center', gap: 1.25 }}>
          <Typography variant="h4" sx={{ color: 'inherit' }}>
            {count}
          </Typography>
          {caption && <Chip variant="combined" color={color} label={caption} size="small" />}
        </Stack>
      </Stack>
    </MainCard>
  );
}

StatCard.propTypes = {
  title: PropTypes.string,
  count: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  color: PropTypes.string,
  caption: PropTypes.string
};
