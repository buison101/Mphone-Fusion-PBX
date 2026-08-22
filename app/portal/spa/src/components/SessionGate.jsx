import { useState } from 'react';
import PropTypes from 'prop-types';

// material-ui
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Alert from '@mui/material/Alert';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Stack from '@mui/material/Stack';
import TextField from '@mui/material/TextField';
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

function IdentityLogin() {
  const { login } = useSession();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  const submit = async (event) => {
    event.preventDefault();
    if (submitting) return;
    setSubmitting(true);
    setError('');
    try {
      const result = await login(email, password);
      if (!result.ok) setError(result.error);
    } catch {
      setError('unavailable');
    } finally {
      setSubmitting(false);
    }
  };

  const errorMessageId =
    error === 'rate_limited'
      ? 'login.error.rateLimited'
      : error === 'forbidden'
        ? 'login.error.forbidden'
        : error === 'unavailable' || error === 'service_unavailable'
          ? 'login.error.unavailable'
          : 'login.error.invalid';

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', p: 3, bgcolor: 'background.default' }}>
      <Card sx={{ width: '100%', maxWidth: 420 }}>
        <CardContent sx={{ p: { xs: 3, sm: 4 } }}>
          <Stack component="form" onSubmit={submit} sx={{ gap: 2.25 }}>
            <Stack sx={{ gap: 0.75 }}>
              <Typography variant="h3">
                <FormattedMessage id="login.title" />
              </Typography>
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                <FormattedMessage id="login.subtitle" />
              </Typography>
            </Stack>
            {error && (
              <Alert severity="error">
                <FormattedMessage id={errorMessageId} />
              </Alert>
            )}
            <TextField
              type="email"
              name="email"
              autoComplete="username"
              label={<FormattedMessage id="login.email" />}
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              required
              fullWidth
            />
            <TextField
              type="password"
              name="password"
              autoComplete="current-password"
              label={<FormattedMessage id="login.password" />}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
              fullWidth
            />
            <Button type="submit" variant="contained" size="large" disabled={submitting}>
              <FormattedMessage id={submitting ? 'login.submitting' : 'login.submit'} />
            </Button>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}

export default function SessionGate({ children }) {
  const { session, loading, error, reload } = useSession();

  if (loading) return <Loader />;

  if (error === 'unauthorized') return <IdentityLogin />;

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
