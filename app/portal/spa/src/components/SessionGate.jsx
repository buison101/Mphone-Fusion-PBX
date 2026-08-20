import PropTypes from 'prop-types';

// material-ui
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

// third-party
import { FormattedMessage } from 'react-intl';

// project imports
import Loader from 'components/Loader';
import useSession from 'hooks/useSession';
import { ADMIN_URL } from 'config';

// ==============================|| SESSION GATE ||============================== //
//
// Nothing is routed until the server has confirmed who is signed in. A missing
// session redirects to the PHP login inside SessionContext, so only the refused
// and unreachable cases are handled here.

function Message({ title, detail, action }) {
  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', p: 3 }}>
      <Stack sx={{ gap: 1.5, maxWidth: 420, textAlign: 'center', alignItems: 'center' }}>
        <Typography variant="h4">{title}</Typography>
        <Typography variant="body2" sx={{ color: 'text.secondary' }}>
          {detail}
        </Typography>
        {action}
      </Stack>
    </Box>
  );
}

Message.propTypes = { title: PropTypes.node, detail: PropTypes.node, action: PropTypes.node };

export default function SessionGate({ children }) {
  const { session, loading, error, reload } = useSession();

  if (loading) return <Loader />;

  if (error === 'forbidden') {
    return (
      <Message
        title={<FormattedMessage id="gate.forbidden.title" />}
        detail={<FormattedMessage id="gate.forbidden.detail" />}
        action={
          <Button variant="contained" href={ADMIN_URL}>
            <FormattedMessage id="gate.forbidden.action" />
          </Button>
        }
      />
    );
  }

  if (error || !session) {
    return (
      <Message
        title={<FormattedMessage id="gate.unreachable.title" />}
        detail={<FormattedMessage id="gate.unreachable.detail" />}
        action={
          <Button variant="contained" onClick={reload}>
            <FormattedMessage id="gate.unreachable.action" />
          </Button>
        }
      />
    );
  }

  return children;
}

SessionGate.propTypes = { children: PropTypes.node };
