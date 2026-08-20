// Client for the FusionPBX websocket router (core/websockets).
//
// Protocol, as implemented by websocket_service.php and subscriber.php:
//   1. the server answers a new socket with {status_code: 407, service_name: 'authentication'}
//   2. the client replies with a request for the 'authentication' service carrying the token
//   3. once authenticated the client may request topics and receives pushed events
//
// Every request carries the token because the router holds no session for the
// socket. The token itself is minted by /app/portal/api/session.php.

const AUTH_REQUIRED_CODE = 407;

export default class WebsocketClient {
  constructor({ url, token, onStatus, onEvent, onAuthenticated, onTokenRejected }) {
    this.url = url;
    this.token = token;
    this.onStatus = onStatus || (() => {});
    this.onEvent = onEvent || (() => {});
    this.onAuthenticated = onAuthenticated || (() => {});
    this.onTokenRejected = onTokenRejected || (() => {});

    this.ws = null;
    this.nextId = 1;
    this.pending = new Map();
    this.reconnectAttempts = 0;
    this.reconnectTimer = null;
    this.closedByUs = false;
  }

  connect() {
    this.closedByUs = false;
    this.onStatus('connecting');

    try {
      this.ws = new WebSocket(this.url);
    } catch {
      this.scheduleReconnect();
      return;
    }

    this.ws.addEventListener('open', () => {
      this.reconnectAttempts = 0;
      this.onStatus('connected');
    });

    this.ws.addEventListener('message', (event) => this.handleMessage(event));

    this.ws.addEventListener('close', () => {
      this.onStatus('disconnected');
      if (!this.closedByUs) {
        this.scheduleReconnect();
      }
    });

    this.ws.addEventListener('error', () => {
      // the close handler owns the reconnect, this only surfaces the state
      this.onStatus('error');
    });
  }

  // A socket dropped by the router is retried with a capped exponential backoff
  // so a restarting service does not get hammered by every open browser tab.
  scheduleReconnect() {
    if (this.reconnectTimer) return;

    const delay = Math.min(1000 * 2 ** this.reconnectAttempts, 30000);
    this.reconnectAttempts += 1;
    this.onStatus('reconnecting');

    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, delay);
  }

  handleMessage(event) {
    let message;
    try {
      message = JSON.parse(event.data);
    } catch {
      return;
    }

    // the router asks for credentials before anything else is accepted
    if (message.status_code === AUTH_REQUIRED_CODE && message.service_name === 'authentication') {
      this.request('authentication')
        .then(() => this.onAuthenticated())
        .catch(() => this.onTokenRejected());
      return;
    }

    const requestId = message.request_id ?? null;

    if (requestId && this.pending.has(requestId)) {
      const { resolve, reject } = this.pending.get(requestId);
      this.pending.delete(requestId);

      const code = message.code ?? 200;
      const status = message.status ?? 'ok';

      if (status === 'ok' && code >= 200 && code < 300) {
        resolve(message);
      } else {
        const error = new Error(`websocket request failed (${code})`);
        error.code = code;
        reject(error);
        return;
      }

      // in.progress replies stream the current calls on the same request id,
      // so the payload is dispatched as an event too or the first batch is lost
      if (message.topic && message.payload && typeof message.payload === 'object') {
        this.onEvent(message.topic, message.payload, message);
      }
      return;
    }

    if (message.topic && message.payload && typeof message.payload === 'object') {
      this.onEvent(message.topic, message.payload, message);
    }
  }

  request(service, topic = null, payload = {}) {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      return Promise.reject(new Error('socket is not open'));
    }

    const request_id = String(this.nextId++);
    const envelope = {
      request_id,
      service,
      ...(topic !== null ? { topic } : {}),
      token: this.token,
      payload
    };

    this.ws.send(JSON.stringify(envelope));

    return new Promise((resolve, reject) => {
      this.pending.set(request_id, { resolve, reject });
    });
  }

  // Replaces the token used by later requests, for example after the portal
  // renews it before expiry. The next reconnect authenticates with the new one.
  setToken(token) {
    this.token = token;
  }

  close() {
    this.closedByUs = true;
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}
