import PropTypes from 'prop-types';
import { createContext, useCallback, useEffect, useMemo, useRef, useState } from 'react';

// project imports
import { SESSION_URL, IDENTITY_URL } from 'config';

// ==============================|| SESSION CONTEXT ||============================== //
//
// The portal has no login of its own. It rides on the FusionPBX PHP session and
// asks the server who is signed in, what they may see, and for a websocket token.
// A 401 means the PHP session is gone, so the browser is sent back to the login
// page rather than showing an empty portal.

export const SessionContext = createContext(undefined);

// the token is renewed a minute before the server would reject it
const RENEW_MARGIN_SECONDS = 60;

// The document icon is part of the same branding the drawer logo comes from, so it
// is applied from the session rather than shipped in the build. Replacing the tag
// rather than editing it in place makes the browser refetch.
function applyFavicon(href) {
  if (!href) return;

  document.querySelectorAll("link[rel='icon'], link[rel='shortcut icon']").forEach((node) => node.remove());

  const link = document.createElement('link');
  link.rel = 'icon';
  link.href = href;
  document.head.appendChild(link);
}

export function SessionProvider({ children }) {
  const [session, setSession] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [loginCsrf, setLoginCsrf] = useState('');
  const renewTimer = useRef(null);

  const load = useCallback(async () => {
    try {
      const response = await fetch(SESSION_URL, {
        credentials: 'same-origin',
        headers: { Accept: 'application/json' }
      });

      if (response.status === 401) {
        const data = await response.json().catch(() => ({}));
        setLoginCsrf(data.login_csrf || '');
        setSession(null);
        setError('unauthorized');
        setLoading(false);
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
      applyFavicon(data?.branding?.favicon);
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

  const login = useCallback(
    async (email, password) => {
      const response = await fetch(IDENTITY_URL, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': loginCsrf },
        body: JSON.stringify({ action: 'login', email, password })
      });
      const data = await response.json().catch(() => ({}));
      if (!response.ok) return { ok: false, error: data.error || 'unavailable' };
      await load();
      return { ok: true };
    },
    [load, loginCsrf]
  );

  const logout = useCallback(async () => {
    const response = await fetch(IDENTITY_URL, {
      method: 'POST',
      credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': session?.csrf || '' },
      body: JSON.stringify({ action: 'logout' })
    });
    const data = await response.json().catch(() => ({}));
    setSession(null);
    setLoginCsrf(data.login_csrf || '');
    setError('unauthorized');
    return response.ok;
  }, [session]);

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
      login,
      logout,
      can: (permission) => Boolean(session?.permissions?.[permission])
    }),
    [session, loading, error, load, login, logout]
  );

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

SessionProvider.propTypes = { children: PropTypes.node };
