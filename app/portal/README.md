# Portal

Self service portal for end customers, served at `/p/`.

The portal is a React single page application. It does not replace the PHP admin
pages, it sits beside them: the 300+ administration pages stay in PHP and this
application covers the screens where a full page reload gets in the way.

## How it fits together

```
browser ──► /p/                                  static build, served by nginx
        ──► /app/portal/service/session.php      who am I, what may I see, websocket token
        ──► /app/portal/service/dashboard.php    call history, read only
        ──► wss://host/websockets/               live call events (core/websockets)
```

The dashboard deliberately reads from two places. The websocket reports what is
happening right now and the CDR endpoint reports what already happened, so a
stalled socket cannot make the history look wrong, or the reverse.

There is no separate login. The portal rides on the FusionPBX PHP session:

1. `session.php` answers `401` when the PHP session is missing and the browser is
   sent to the normal login page.
2. When signed in it returns the user, the domain, the subset of permissions the
   interface branches on, and a short lived websocket token.
3. The token is written to `/dev/shm` by `subscriber::save_token` so the
   websocket router can authorise the socket without a PHP session.

Call scope is decided by the server, never by the browser. A subscriber holding
neither `call_active_all` nor `call_active_domain` only receives events for the
extensions assigned to them, which is what an end customer gets.

## Appearance and language

The header carries two controls:

- **Appearance** — light, dark, or follow the operating system. The choice is
  stored under `theme-mode`. The dark palette is *selected*, not derived: its
  steps come from the Ant Design dark ramps in `src/themes/palette.js`, because
  flipping the light values produces mud on a dark surface.
- **Language** — English and Vietnamese, stored under `portal-locale`. The first
  visit follows the browser preference. Catalogues live in `src/locales/`.

Chart colours differ per mode and were both checked for colour vision deficiency
separation: `#1677ff` / `#ff4d4f` on light, `#1668dc` / `#d32029` on dark.

## Requirements

- Node 20 or newer (Vite 8). Debian 12 ships Node 18, so install from NodeSource.
- The `fusionpbx-websockets` and `fusionpbx-active-calls` services must be running.

## Build

```sh
cd app/portal/spa
npm install
npm run build          # writes to /var/www/fusionpbx/p
```

`p/` is generated and is not committed. Rebuild after changing anything in `src/`.

## Develop

```sh
npm start              # vite dev server on :3000
```

The dev server needs `/app/portal/service` and `/websockets/` proxied to the PHP host,
otherwise sign in through the normal interface first and browse the built `/p/`.

## Permissions

| Permission | Effect |
| --- | --- |
| `portal_view` | May open the portal at all. Granted to superadmin, admin, user. |
| `call_active_view` | Required by the active.calls service to answer `in.progress`. |
| `call_active_hangup` | Shows the hangup button. Not granted to the user group. |
| `call_active_domain` | Widens live call scope from own extensions to the whole domain. |
| `xml_cdr_view` | Required for the dashboard history. Without it the page still shows live state. |
| `xml_cdr_domain` | Widens history scope to the whole domain. Not granted to the user group. |
| `call_active_all` | Widens scope to every domain. Superadmin only. |

## After installing

`portal_view` is read from the PHP session, which is filled at login. Anyone
already signed in when the permission was added has to sign out and back in
once before the portal stops answering `403`.

The permission and the menu entry were inserted directly rather than through
`core/upgrade/upgrade.php -p` or `-m`. Both of those routines delete before they
rebuild (`permission::restore()` calls `delete()`, `menu_restore_default.php`
calls `restore_delete()`), so running them on this system would discard the
permission and menu customisations already in place.
