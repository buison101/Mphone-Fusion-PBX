# Browser Phone for FusionPBX

Independent integration of Browser Phone 0.3.29 with FusionPBX/FreeSWITCH,
served from `/app/webphone/`.
It does not include or depend on `app/webphone`.

- Authenticates through the FusionPBX session.
- Lets signed-in users select any enabled extension assigned to their account.
- Uses the extension UUID as Browser Phone's stable internal profile ID.
- Applies the assigned-extension rule to every account, including admins and superadmins.
- Shows the selector at the extension name and opens the dial pad on startup.
- Opens from the permission-aware FusionPBX header action rather than the side menu.
- Uses the same session-configured favicon as the main FusionPBX interface.
- Renders inside the standard FusionPBX content area in an isolated same-origin iframe.
- Follows the English/Vietnamese language selected in the FusionPBX header and hides
  Browser Phone's independent language selector.
- Loads all JavaScript and CSS locally.
- Connects to `wss://<current-host>/browser-phone-ws`. Nginx terminates TLS and
  forwards to the FreeSWITCH WS listener on port 5066. This module's private
  `phone.js` transport adapter reports `WS` in SIP Via/Contact for FreeSWITCH.
- The SIP Contact explicitly includes `transport=ws` so inbound calls reuse the
  registered WebSocket path instead of attempting UDP to the browser contact.
- Keeps account settings and video disabled by default.

Runtime settings are under **Advanced > Default Settings > browser_phone**.
For Internet users, configure valid public SIP/RTP addresses and TURN servers.

The upstream Browser Phone client is licensed under AGPL-3.0. Preserve the
license and make the corresponding source available when distributing or
providing a modified version over a network.
