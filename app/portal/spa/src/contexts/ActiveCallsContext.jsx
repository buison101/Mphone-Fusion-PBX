import PropTypes from 'prop-types';
import { createContext, useCallback, useEffect, useMemo, useRef, useState } from 'react';

// project imports
import WebsocketClient from 'lib/websocket_client';
import useSession from 'hooks/useSession';

// ==============================|| ACTIVE CALLS CONTEXT ||============================== //
//
// Owns the single websocket connection for the portal. The header badge and the
// calls table both read from here, so the browser holds one socket no matter how
// many components display call state.
//
// Scope is decided on the server: a subscriber without call_active_all or
// call_active_domain only ever receives events for their own extensions.

export const ActiveCallsContext = createContext(undefined);

const CALL_EVENTS = ['CHANNEL_CREATE', 'CHANNEL_CALLSTATE', 'CHANNEL_EXECUTE', 'CALL_UPDATE', 'CHANNEL_DESTROY'];

// The in.progress bootstrap reports every existing call as ringing. Those are
// already established, so they are shown as answered instead.
function normalizeState(call, fromRequest) {
  const state = String(call.answer_state ?? '').toLowerCase();
  if (state === 'ringing' && fromRequest) return 'answered';
  return state;
}

// Mirrors the arrow logic of the PHP page: a call_direction set by the dialplan
// wins, an rdnis on the other leg means the call came from outside.
function deriveDirection(call, previous) {
  const applicationData = call.application_data ?? '';

  if (applicationData === 'app.lua voicemail') return 'voicemail';
  if (applicationData === 'call_direction=outbound') return 'outbound';
  if (applicationData === 'call_direction=inbound') return 'inbound';
  if (applicationData === 'call_direction=local') return 'local';

  if (call.variable_user_exists === 'true' && call.variable_from_user_exists === 'true') return 'local';
  if ((call.other_leg_rdnis ?? '') !== '') return 'inbound';

  return call.variable_call_direction || call.call_direction || previous?.direction || '';
}

export function ActiveCallsProvider({ children }) {
  const { session } = useSession();
  const [calls, setCalls] = useState(() => new Map());
  const [status, setStatus] = useState('idle');
  const clientRef = useRef(null);

  const applyEvent = useCallback((topic, payload) => {
    if (!CALL_EVENTS.includes(topic)) return;

    const uniqueId = payload.unique_id;
    if (!uniqueId) return;

    const fromRequest = payload.__from_request === true;
    const state = normalizeState(payload, fromRequest);

    setCalls((current) => {
      const next = new Map(current);

      if (topic === 'CHANNEL_DESTROY' || state === 'hangup') {
        next.delete(uniqueId);
        return next;
      }

      const previous = next.get(uniqueId);

      next.set(uniqueId, {
        ...previous,
        ...payload,
        unique_id: uniqueId,
        answer_state: state || previous?.answer_state || '',
        direction: deriveDirection(payload, previous),
        created_time: previous?.created_time ?? Number(payload.caller_channel_created_time ?? 0)
      });

      return next;
    });
  }, []);

  useEffect(() => {
    if (!session?.websocket) return undefined;

    const client = new WebsocketClient({
      url: session.websocket.url,
      token: session.websocket.token,
      onStatus: setStatus,
      onEvent: applyEvent,
      onAuthenticated: () => {
        setStatus('subscribed');
        // ask for what is already up before the first live event arrives
        client.request('active.calls', 'in.progress').catch(() => setStatus('error'));
      },
      onTokenRejected: () => setStatus('unauthorized')
    });

    clientRef.current = client;
    client.connect();

    return () => {
      client.close();
      clientRef.current = null;
      setCalls(new Map());
    };
  }, [session, applyEvent]);

  // The service refuses a hangup without the permission, so the button that
  // calls this is hidden unless the session reports it.
  const hangup = useCallback((uniqueId) => {
    const client = clientRef.current;
    if (!client) return Promise.reject(new Error('not connected'));
    return client.request('active.calls', 'hangup', { unique_id: uniqueId });
  }, []);

  const list = useMemo(() => Array.from(calls.values()).sort((a, b) => (b.created_time || 0) - (a.created_time || 0)), [calls]);

  const value = useMemo(() => ({ calls: list, status, hangup }), [list, status, hangup]);

  return <ActiveCallsContext.Provider value={value}>{children}</ActiveCallsContext.Provider>;
}

ActiveCallsProvider.propTypes = { children: PropTypes.node };
