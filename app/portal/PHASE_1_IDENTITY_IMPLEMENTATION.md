# Customer Identity Phase 1 — Implementation

Status: implemented for the LAN development environment on 2026-08-22. The v1
login API remains available for rollback and existing APK compatibility.

## Delivered

- tenant-aware v2 login for temporary `fusion_user` account actors and Extension
  actors;
- shared login tenant mapped to the FusionPBX Domain currently named
  `192.168.1.201`;
- 15-minute ES256 access tokens with issuer `mphone-identity`, audience
  `mphone-api`, and token version 2;
- opaque 30-day rotating refresh tokens stored as SHA-256 hashes;
- refresh-token family reuse detection and revocation;
- revocable per-installation Device Sessions, logout, and logout-all endpoints;
- login audit/rate-limit records without credentials or bearer tokens;
- v2 token verification in the Edge gateway and FusionPBX call-forward API;
- scope checks for call forwarding and push registration;
- push registrations bound to the hashed installation ID and disabled on logout;
- encrypted Android storage for access and refresh credentials;
- explicit Managed Account, Mphone Extension, third-party SIP, and legacy-unknown
  account origins;
- Managed Account/Multi-SIP state handling: existing Multi-SIP registrations are
  suspended, kept on the device, hidden while managed mode is active, and restored
  on logout;
- separate Account and Extension selections on the Mphone login screen;
- automatic serialized token refresh before protected mobile operations;
- legacy HS256/API v1 behavior retained during migration;
- reusable SIP password provisioning retained behind
  `MPHONE_LEGACY_SIP_PASSWORD_RESPONSE=true`.

Google, Customer, Membership, and final Identity subjects remain Phase 2. An
account token in Phase 1 carries `subject_kind=fusion_user` so it cannot be
mistaken for the Phase 2 Identity UUID.

## Server files

- `/opt/supabase/supabase-project/volumes/db/init/mphone_identity_phase1.sql`
- `/opt/supabase/supabase-project/volumes/functions/mphone-auth-v2/index.ts`
- `/opt/supabase/supabase-project/volumes/functions/_shared/mphone-auth-v2.ts`
- `/opt/supabase/supabase-project/volumes/functions/_shared/mphone-auth.ts`
- `/opt/supabase/supabase-project/volumes/functions/main/index.ts`
- `/opt/supabase/supabase-project/volumes/functions/mphone-push-register/index.ts`
- `/opt/supabase/supabase-project/volumes/functions/fusionpbx-call-forward/index.ts`
- `/opt/supabase/supabase-project/docker-compose.yml`
- `/var/www/fusionpbx/app/mphone_api/call_forward.php`

## Key material

The ES256 key pair is generated outside every repository:

```text
/etc/mphone/auth-v2-private.pem  mode 0600
/etc/mphone/auth-v2-public.pem   mode 0644
```

The Edge main runtime reads the files and passes PEM content to isolated workers.
Only the public key is needed by FusionPBX verification. Private key contents,
JWTs, refresh tokens, SIP passwords, and FCM tokens must never be committed or
copied into this document.

## Endpoints

```text
POST /functions/v1/mphone-auth-v2/login
POST /functions/v1/mphone-auth-v2/refresh
POST /functions/v1/mphone-auth-v2/logout
POST /functions/v1/mphone-auth-v2/logout-all
GET  /functions/v1/mphone-auth-v2/session
GET  /functions/v1/mphone-auth-v2/devices
POST /functions/v1/mphone-auth-v2/revoke-device
```

Login requires an explicit actor mode and tenant:

```json
{
  "login_mode": "account",
  "tenant": "shared",
  "login": "email-or-username",
  "password": "redacted",
  "installation_id": "client-generated-opaque-id"
}
```

Extension login uses `login_mode=extension`. The server resolves `tenant` to a
trusted Domain before querying FusionPBX; the client does not authorize itself by
submitting a `domain_uuid`.

## Database installation

The migration is idempotent and is installed on an existing Supabase database
with:

```sh
docker exec -i supabase-db psql -v ON_ERROR_STOP=1 -U postgres -d postgres \
  < /opt/supabase/supabase-project/volumes/db/init/mphone_identity_phase1.sql
```

The LAN shared tenant is currently seeded as:

```text
tenant_key: shared
login_host: login.mphone.vn
tenant_type: shared
FusionPBX Domain: 192.168.1.201
```

The Domain UUID is deployment data and must be resolved again rather than copied
when installing another environment.

## Rollback

Server rollback does not require dropping Phase 1 tables:

1. set the Android `fusionpbx/use_auth_v2` preference to false or release an APK
   with that default disabled;
2. keep `/functions/v1/fusionpbx-login` available;
3. stop routing new clients to `mphone-auth-v2`;
4. revoke active v2 sessions if required;
5. leave the additive database tables in place for audit and later retry.

Do not remove the ES256 public key while unexpired v2 sessions are still expected
to reach FusionPBX APIs.

## Verification performed

- schema migration was applied twice successfully to prove idempotency;
- Docker Compose configuration validation passed;
- PHP syntax validation passed for the modified Mphone API;
- Extension login returned one tenant-scoped Extension and a 900-second token;
- session validation accepted a fresh token;
- refresh rotation returned a new token;
- reuse of the previous refresh token returned `401 refresh_token_reuse`;
- the replacement access token was rejected after family revocation;
- v2 call-forward read succeeded for the token's Extension;
- cross-Extension call-forward read returned 403;
- logout returned success and the old access token then returned 401;
- device listing identified the current session, device revoke succeeded, and the
  revoked current session then returned 401;
- a test push registration was disabled by logout and the test row was removed;
- legacy v1 invalid login continued to return the existing 401 behavior;
- Android resource XML parsed successfully.

### Android build limitation in the Debian guest

The mounted Android repository points `local.properties` at the host's Windows
SDK (`D:\Programs\AndroidStudio\Sdk`). The Debian guest initially had neither a
JDK nor an Android API 37 SDK. Two attempts to install OpenJDK from the Debian
security and main mirrors were stopped during download after the mirrors made no
practical progress; package installation had not begun and `dpkg --audit`
remained clean. Therefore no new APK was produced in the guest. Source/XML and
server integration checks passed, but `testDebugUnitTest` and `assembleDebug`
must still be run with the existing Windows Android Studio toolchain before a
pilot APK is distributed.
