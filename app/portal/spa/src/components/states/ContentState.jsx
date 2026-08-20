import PropTypes from 'prop-types';

// material-ui
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

// ==============================|| CONTENT STATE ||============================== //

export default function ContentState({ state, title, detail, actionLabel, onAction, compact = false }) {
  if (state === 'loading') {
    return (
      <Stack role="status" sx={{ minHeight: compact ? 96 : 180, alignItems: 'center', justifyContent: 'center', gap: 1.5 }}>
        <CircularProgress size={28} />
        {title && (
          <Typography variant="body2" sx={{ color: 'text.secondary' }}>
            {title}
          </Typography>
        )}
      </Stack>
    );
  }

  if (state === 'error') {
    return (
      <Alert
        severity="error"
        action={
          actionLabel && onAction ? (
            <Button color="inherit" size="small" onClick={onAction}>
              {actionLabel}
            </Button>
          ) : null
        }
      >
        <Typography variant="subtitle2">{title}</Typography>
        {detail && <Typography variant="body2">{detail}</Typography>}
      </Alert>
    );
  }

  return (
    <Box sx={{ minHeight: compact ? 96 : 180, display: 'flex', alignItems: 'center', justifyContent: 'center', p: 3 }}>
      <Stack sx={{ maxWidth: 480, alignItems: 'center', gap: 1, textAlign: 'center' }}>
        <Typography variant="subtitle1">{title}</Typography>
        {detail && (
          <Typography variant="body2" sx={{ color: 'text.secondary' }}>
            {detail}
          </Typography>
        )}
        {actionLabel && onAction && (
          <Button size="small" onClick={onAction}>
            {actionLabel}
          </Button>
        )}
      </Stack>
    </Box>
  );
}

ContentState.propTypes = {
  state: PropTypes.oneOf(['loading', 'empty', 'error', 'forbidden']).isRequired,
  title: PropTypes.node.isRequired,
  detail: PropTypes.node,
  actionLabel: PropTypes.node,
  onAction: PropTypes.func,
  compact: PropTypes.bool
};
