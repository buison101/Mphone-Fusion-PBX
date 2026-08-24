import { useEffect, useMemo, useRef, useState } from 'react';
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
import { ADMIN_URL, GOOGLE_OAUTH_URL } from 'config';

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
  const { login, lifecycle, completeGoogleLogin } = useSession();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [passwordConfirm, setPasswordConfirm] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const googleCompletionStarted = useRef(false);
  const path = window.location.pathname;
  const params = useMemo(() => new URLSearchParams(window.location.search), []);
  const token = params.get('token') || '';
  const purpose = params.get('purpose') || '';
  const initialMode = path.endsWith('/reset-password') ? 'reset' : path.endsWith('/verify-email') ? 'verify' : 'login';
  const [mode, setMode] = useState(initialMode);
  const requiresNewPassword = mode === 'reset' || (mode === 'verify' && purpose !== 'change_email');

  useEffect(() => {
    if (params.get('google') !== 'complete' || googleCompletionStarted.current) return;
    googleCompletionStarted.current = true;
    setSubmitting(true);
    completeGoogleLogin().then((result) => {
      window.history.replaceState({}, '', '/p/');
      if (!result.ok) setError(result.error);
      setSubmitting(false);
    });
  }, [completeGoogleLogin, params]);

  const cleanUrl = () => window.history.replaceState({}, '', '/p/');

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

  const requestRecovery = async (event) => {
    event.preventDefault();
    if (submitting) return;
    setSubmitting(true);
    setError('');
    const result = await lifecycle({ action: 'request_recovery', email });
    setSubmitting(false);
    if (!result.ok) {
      setError(result.data?.error || 'unavailable');
      return;
    }
    setSuccess('recoveryRequested');
  };

  const confirmToken = async (event) => {
    event.preventDefault();
    if (submitting) return;
    if (!token) {
      setError('invalid_or_expired_token');
      return;
    }
    if (requiresNewPassword && password !== passwordConfirm) {
      setError('password_mismatch');
      return;
    }
    setSubmitting(true);
    setError('');
    const action = mode === 'reset' ? 'confirm_recovery' : purpose === 'change_email' ? 'confirm_email_change' : 'confirm_verification';
    const result = await lifecycle({ action, token, ...(requiresNewPassword ? { password } : {}) });
    setSubmitting(false);
    if (!result.ok) {
      setError(result.data?.error || 'invalid_or_expired_token');
      return;
    }
    cleanUrl();
    setPassword('');
    setPasswordConfirm('');
    setSuccess(mode === 'reset' ? 'passwordReset' : 'emailVerified');
    setMode('login');
  };

  const errorMessageId =
    error === 'rate_limited'
      ? 'login.error.rateLimited'
      : error === 'forbidden'
        ? 'login.error.forbidden'
        : error === 'unavailable' || error === 'service_unavailable'
          ? 'login.error.unavailable'
          : error === 'password_mismatch'
            ? 'lifecycle.error.passwordMismatch'
            : error === 'invalid_or_expired_token'
              ? 'lifecycle.error.invalidToken'
              : 'login.error.invalid';

  const backToLogin = () => {
    cleanUrl();
    setMode('login');
    setError('');
    setSuccess('');
  };

  const titleId =
    mode === 'forgot'
      ? 'lifecycle.forgot.title'
      : mode === 'reset'
        ? 'lifecycle.reset.title'
        : mode === 'verify'
          ? 'lifecycle.verify.title'
          : 'login.title';
  const subtitleId =
    mode === 'forgot'
      ? 'lifecycle.forgot.subtitle'
      : mode === 'reset'
        ? 'lifecycle.reset.subtitle'
        : mode === 'verify'
          ? purpose === 'change_email'
            ? 'lifecycle.verifyChange.subtitle'
            : 'lifecycle.verify.subtitle'
          : 'login.subtitle';

  const formSubmit = mode === 'forgot' ? requestRecovery : mode === 'reset' || mode === 'verify' ? confirmToken : submit;

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', p: 3, bgcolor: 'background.default' }}>
      <Card sx={{ width: '100%', maxWidth: 420 }}>
        <CardContent sx={{ p: { xs: 3, sm: 4 } }}>
          <Stack component="form" onSubmit={formSubmit} sx={{ gap: 2.25 }}>
            <Stack sx={{ gap: 0.75 }}>
              <Typography variant="h3">
                <FormattedMessage id={titleId} />
              </Typography>
              <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                <FormattedMessage id={subtitleId} />
              </Typography>
            </Stack>
            {success && (
              <Alert severity="success">
                <FormattedMessage id={`lifecycle.success.${success}`} />
              </Alert>
            )}
            {error && (
              <Alert severity="error">
                <FormattedMessage id={errorMessageId} />
              </Alert>
            )}
            {(mode === 'login' || mode === 'forgot') && (
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
            )}
            {(mode === 'login' || requiresNewPassword) && (
              <TextField
                type="password"
                name="password"
                autoComplete={requiresNewPassword ? 'new-password' : 'current-password'}
                label={<FormattedMessage id={requiresNewPassword ? 'lifecycle.newPassword' : 'login.password'} />}
                helperText={requiresNewPassword ? <FormattedMessage id="lifecycle.passwordHelp" /> : undefined}
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                inputProps={requiresNewPassword ? { minLength: 12, maxLength: 128 } : undefined}
                required
                fullWidth
              />
            )}
            {requiresNewPassword && (
              <TextField
                type="password"
                name="password_confirm"
                autoComplete="new-password"
                label={<FormattedMessage id="lifecycle.confirmPassword" />}
                value={passwordConfirm}
                onChange={(event) => setPasswordConfirm(event.target.value)}
                inputProps={{ minLength: 12, maxLength: 128 }}
                required
                fullWidth
              />
            )}
            <Button type="submit" variant="contained" size="large" disabled={submitting}>
              <FormattedMessage
                id={
                  submitting
                    ? 'login.submitting'
                    : mode === 'forgot'
                      ? 'lifecycle.forgot.submit'
                      : mode === 'reset'
                        ? 'lifecycle.reset.submit'
                        : mode === 'verify'
                          ? purpose === 'change_email'
                            ? 'lifecycle.verifyChange.submit'
                            : 'lifecycle.verify.submit'
                          : 'login.submit'
                }
              />
            </Button>
            {mode === 'login' && (
              <Button component="a" href={`${GOOGLE_OAUTH_URL}?action=start`} variant="outlined" size="large" disabled={submitting}>
                <FormattedMessage id="login.google" />
              </Button>
            )}
            {mode === 'login' ? (
              <Button
                variant="text"
                onClick={() => {
                  setMode('forgot');
                  setError('');
                  setSuccess('');
                }}
              >
                <FormattedMessage id="lifecycle.forgot.link" />
              </Button>
            ) : (
              <Button variant="text" onClick={backToLogin}>
                <FormattedMessage id="lifecycle.backToLogin" />
              </Button>
            )}
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
