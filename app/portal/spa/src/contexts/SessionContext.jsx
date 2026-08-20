import PropTypes from 'prop-types';
import { createContext, useCallback, useEffect, useMemo, useRef, useState } from 'react';

// project imports
import { SESSION_URL, LOGIN_URL, BASE_PATH } from 'config';

// ==============================|| SESSION CONTEXT ||============================== //
//
// The portal has no login of its own. It rides on the FusionPBX PHP session and
// asks the server who is signed in, what they may see, and for a websocket token.
// A 401 means the PHP session is gone, so the browser is sent back to the login
// page rather than showing an empty portal.

export const SessionContext = createContext(undefined);

// the token is renewed a minute before the server would reject it
const RENEW_MARGIN_SECONDS = 60;

export function SessionProvider({ children }) {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const renewTimer = useRef(null);

  const load = useCallback(async () => {
    try {
      const response = await fetch(SESSION_URL, {
        credentials: 'same-origin',
        headers: { Accept: 'application/json' }
      });

      if (response.status === 401) {
        window.location.href = `${LOGIN_URL}?path=${encodeURIComponent(`${BASE_PATH}/`)}`;
        return null;
      }

      if (response.status === 403) {
        setError('forbidden');
        setLoading(false);
        return null;
      }

      if (!response.ok) {
        setError('unavailable');
        setLoading(false);
        return null;
      }

      const data = await response.json();
      setSession(data);
      setError(null);
      setLoading(false);
      return data;
    } catch {
      setError('unavailable');
      setLoading(false);
      return null;
    }
  }, []);

  useEffect(() => {
    load();
    return () => {
      if (renewTimer.current) clearTimeout(renewTimer.current);
    };
  }, [load]);

  // A single page application outlives its token, so a renew is scheduled from
  // the lifetime the server reported instead of waiting for the socket to fail.
  useEffect(() => {
    if (!session?.websocket?.expires_in) return undefined;

    const delay = Math.max(session.websocket.expires_in - RENEW_MARGIN_SECONDS, 30) * 1000;
    renewTimer.current = setTimeout(() => load(), delay);

    return () => {
      if (renewTimer.current) clearTimeout(renewTimer.current);
    };
  }, [session, load]);

  const value = useMemo(
    () => ({
      session,
      loading,
      error,
      reload: load,
      can: (permission) => Boolean(session?.permissions?.[permission])
    }),
    [session, loading, error, load]
  );

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

SessionProvider.propTypes = { children: PropTypes.node };
