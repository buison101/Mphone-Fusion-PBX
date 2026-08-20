// material-ui
import Chip from '@mui/material/Chip';

// third-party
import { useIntl } from 'react-intl';

// project imports
import useActiveCalls from 'hooks/useActiveCalls';

// ==============================|| HEADER CONTENT - CONNECTION STATUS ||============================== //
//
// A portal that silently stops receiving events looks the same as a quiet PBX,
// so the socket state is always visible rather than only logged to the console.

const COLOR = {
  subscribed: 'success',
  connecting: 'warning',
  connected: 'warning',
  reconnecting: 'warning',
  idle: 'secondary',
  disconnected: 'error',
  unauthorized: 'error',
  error: 'error'
};

export default function ConnectionStatus() {
  const { status } = useActiveCalls();
  const intl = useIntl();

  const label = intl.formatMessage({ id: `status.${status}`, defaultMessage: status });

  return <Chip size="small" variant="combined" color={COLOR[status] ?? 'secondary'} label={label} />;
}
