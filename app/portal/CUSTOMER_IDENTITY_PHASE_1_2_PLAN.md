# Customer Identity and Account Management — Phase 1–2 Plan

Status: Phase 1 and the Phase 2 shared-LAN pilot core are implemented. See
`PHASE_1_IDENTITY_IMPLEMENTATION.md` and `PHASE_2_IDENTITY_IMPLEMENTATION.md` for
deployed files, migration, rollback, limitations, and verification evidence.

Date: 2026-08-22

Related preliminary document: `MPHONE_IDENTITY_ACCOUNT_PLAN.md`.

## 1. Purpose

This plan defines the first two phases of a customer identity platform shared by
FusionPBX, the customer Portal, Mphone, and later billing and automation.

The immediate goals are:

1. make the current login and device-session model safe and explicit;
2. introduce Customer, Identity, Membership, PBX Tenant, and Extension Assignment
   as separate concepts;
3. support ordinary customers on one shared FusionPBX Domain;
4. support VIP customers on dedicated FusionPBX Domains while retaining one
   common customer and billing platform;
5. preserve all three Mphone account modes during migration.

Billing, plan selection, invoicing, and payment-provider integration are outside
the implementation scope of these two phases. The data boundaries introduced
here must allow those features to be added without turning FusionPBX users or
Domains into billing records.

## 2. Approved Product Rules

### 2.0 Confirmed Phase 1 decisions

- `login.mphone.vn` is the future common identity entry point for the complete
  product ecosystem. Email/password and Google resolve an Identity and
  Membership before the server selects a PBX Tenant.
- Ordinary customers resolve to the shared PBX tenant (`call.mphone.vn` in the
  target environment). VIP Customers resolve to their own FusionPBX Domain but
  remain in the common customer and future billing platform.
- During LAN development, `192.168.1.201` is an endpoint substitute for
  `call.mphone.vn`; it is not a tenant identifier or Customer identifier.
- When Managed Account mode becomes active, existing Multi-SIP accounts are not
  deleted. They are suspended completely: SIP registration and incoming calls
  stop until the Managed Account logs out, after which they are restored.
- Phase 1 uses a temporary `fusion_user` account subject and prepares the v2
  session contract. Phase 2 replaces that subject with Customer Identity and
  activates email/password, Google, Membership, and Customer resolution.
- Unless superseded by an implementation finding, Phase 1 uses 15-minute access
  tokens, rotating 30-day refresh tokens, server-side device revocation,
  asymmetric signing, parallel v1/v2 compatibility, protected Android token
  storage, and a compatibility flag for reusable SIP password provisioning.

### 2.1 FusionPBX tenancy

- Ordinary customers sign in through one common public login and use one shared
  FusionPBX Domain.
- A shared FusionPBX Domain can contain multiple independent Customers.
- VIP customers may have their own FusionPBX Domain and dedicated login or
  branding.
- Shared and VIP customers use the same Customer Platform and can use the same
  future billing system.
- A FusionPBX `domain_uuid` is a PBX boundary, not necessarily a Customer ID.
- Customer ownership, subscription, and billing must use a platform-owned
  `customer_id`, never `domain_uuid` or `user_uuid` as a substitute.

### 2.2 Mphone login modes

Mphone retains three modes:

1. **Managed Account** — one customer account is active in one application
   installation. It receives all Extensions explicitly assigned for use by that
   account and may access approved Portal/account features.
2. **Mphone Extension** — multiple managed Extensions may be added. Each login
   can read or change only the configuration belonging to that Extension.
3. **Third-party SIP** — multiple external SIP accounts may be added as the free,
   unsupported mode intended to encourage adoption of Mphone.

Managed Account mode and Multi-SIP mode are mutually exclusive at runtime:

```text
Managed Account mode
    `-- one active customer account
        `-- server-provisioned assigned Extensions

Multi-SIP mode
    |-- zero or more Mphone Extension accounts
    `-- zero or more third-party SIP accounts
```

When switching to Managed Account mode, manually configured Extension and
third-party SIP accounts must be suspended and hidden, not silently deleted.
After logout, the user may restore Multi-SIP mode.

"One account per login" is interpreted in Phase 1 as one active Managed Account
per Mphone installation. It does not initially mean that an Identity may have
only one device globally. Server-side device limits will later be controlled by
entitlements.

### 2.3 Email rules

- Every customer Identity has one unique, verified primary email.
- An Identity may authenticate with password, Google, or both after a secure
  provider-linking flow.
- Extension notification email is not an Identity and is not a login name.
- The same notification email may be assigned to multiple Extensions.
- Extension email must not be usable for password reset or account recovery
  unless it is separately verified as an Identity's primary email.

## 3. Identity and Authorization Boundaries

The following objects must remain separate:

| Object | Meaning | Source of truth |
| --- | --- | --- |
| Customer | Paying person or organization | Customer Platform |
| Identity | A human login identity | Auth provider + Customer Platform mapping |
| Membership | Identity's role in a Customer | Customer Platform |
| PBX Tenant | Mapping from Customer to FusionPBX Domain | Customer Platform |
| FusionPBX User | PBX web/permission principal | FusionPBX |
| Extension | SIP endpoint and telephony configuration | FusionPBX |
| Extension Assignment | Identity allowed to use/manage an Extension | Customer Platform, reconciled with FusionPBX |
| Device Session | Revocable Mphone installation session | Customer Platform/session service |
| Third-party SIP Account | External SIP configuration | Device-local storage |

Authorization must be evaluated as:

```text
allowed action = application permission
               x resource scope
               x account/extension status
               x future entitlement
```

FusionPBX permissions continue to answer what a principal can do. Customer and
Extension scope answer which records the principal can do it to. Future
entitlements will answer whether the subscribed product enables the capability.

## 4. Shared-Domain Isolation

The shared Domain creates a stricter isolation requirement than the present
Domain-based model. Two Customers in the same Domain must never gain access to
one another merely because their `domain_uuid` is equal.

Required rules:

- ordinary customer users must not receive Domain-wide permissions such as
  `xml_cdr_domain` or equivalent broad live-call permissions;
- every customer-facing query must be constrained by approved Extension UUIDs or
  another explicit Customer-owned resource list;
- Customer owner/admin means owner/admin inside `customer_id`, not administrator
  of the shared FusionPBX Domain;
- management permission and use permission are separate: a Customer admin may
  manage an Extension without automatically registering it as their personal
  calling identity;
- server-side scope checks are mandatory; React and Android filtering are only
  presentation behavior;
- every shared-Domain API must include negative tests proving that a principal
  from Customer A cannot read or change Customer B data.

VIP customers with a dedicated Domain may receive wider Domain scope only when
their Customer-to-Domain mapping and role explicitly allow it.

## 5. Target Login and Session Model

### 5.1 Managed Account login

```text
email + password, or Google authorization
    -> verify Identity
    -> load active Memberships
    -> resolve active Customer
    -> load Extensions with can_use = true
    -> create revocable Device Session
    -> issue short-lived access token
    -> provision selected/all assigned Extensions
```

"All Extensions" means all Extensions explicitly assigned to that Identity with
`can_use = true`. It never means all Extensions in the shared Domain. A Customer
owner may separately hold `can_manage` permission for a broader set.

The schema should support an Identity belonging to multiple Customers from the
start. Phase 2 UI may automatically select the only active Customer and defer a
Customer picker until a real multi-Customer use case exists.

### 5.2 Mphone Extension login

Extension login creates an Extension actor, not a Customer Identity:

```json
{
  "actor_type": "extension",
  "domain_uuid": "uuid",
  "extension_uuid": "uuid",
  "session_id": "uuid",
  "device_id": "opaque-device-id",
  "scopes": ["extension.self.read", "extension.self.configure", "push.register"]
}
```

An Extension actor must not receive customer, membership, billing, or other
Extension permissions.

Short numeric Extension names are only unambiguous inside a Domain. The login
contract must therefore resolve the Domain by one of these mechanisms:

- the common login is pre-bound to the shared Domain;
- a VIP login host is pre-bound to its dedicated Domain;
- an explicit `extension@domain` or tenant code is supplied; or
- a signed provisioning QR/deep link supplies the tenant identifier.

QR or deep-link provisioning is the preferred future VIP deployment flow.

### 5.3 Third-party SIP login

- third-party credentials remain on the device and are not sent to the Customer
  Platform;
- the account receives no Mphone customer token, Portal access, managed push, or
  server-side configuration rights;
- each account stores an explicit `origin = third_party` marker and visible
  label;
- Mphone Extension accounts store `origin = mphone_extension`; origin must not be
  inferred from the SIP domain;
- UI and support diagnostics must clearly identify unsupported third-party SIP
  accounts without exposing their credentials.

### 5.4 Token and session requirements

Phase 1 tokens must include at least:

- `iss`, `aud`, `sub`, `iat`, `exp`;
- `actor_type`;
- `session_id` and `token_version`;
- `device_id` or a non-sensitive device-session reference;
- `customer_id` for account actors;
- `domain_uuid` and appropriate Extension claims/scopes;
- narrow, versioned scopes.

The session design must provide:

- short-lived access tokens;
- rotating refresh tokens;
- refresh-token reuse detection;
- per-device revoke and logout-all-devices;
- immediate or bounded-time enforcement after Identity, Membership, Domain, User,
  or Extension disablement;
- server-side revalidation of Extension assignment for sensitive operations;
- rate limiting for login, refresh, recovery, provisioning, and device
  registration;
- audit events without JWTs, passwords, SIP credentials, refresh tokens, FCM
  tokens, or Google tokens in logs.

### 5.5 SIP credential transition

The current mobile login path validates and returns reusable SIP passwords. It
may be retained temporarily for compatibility but is not the target contract.

The target is:

1. authenticate the account or Extension with an application credential;
2. authorize the device and Extension assignment;
3. issue a short-lived provisioning envelope or device-specific SIP credential;
4. allow per-device revoke and rotation without changing every phone or desk
   device using the Extension.

Application passwords, account passwords, and SIP registration passwords must
not be treated as the same credential in the target design.

## 6. Phase 2 Minimum Data Model

The exact database types and ownership will be finalized in an implementation
design, but the logical schema is:

```text
identities
  identity_id uuid primary key
  primary_email canonical-email unique not null
  email_verified_at timestamptz
  status

identity_providers
  identity_provider_id uuid primary key
  identity_id uuid references identities
  provider password | google
  provider_subject text
  unique(provider, provider_subject)

customers
  customer_id uuid primary key
  customer_code text unique
  customer_type individual | organization
  status

memberships
  membership_id uuid primary key
  customer_id uuid references customers
  identity_id uuid references identities
  role owner | customer_admin | member | billing_admin
  status
  unique(customer_id, identity_id)

pbx_tenants
  pbx_tenant_id uuid primary key
  customer_id uuid references customers
  fusion_domain_uuid uuid
  tenant_type shared | vip
  login_slug text
  status

extension_assignments
  assignment_id uuid primary key
  customer_id uuid references customers
  identity_id uuid references identities
  fusion_domain_uuid uuid
  extension_uuid uuid
  can_use boolean
  can_manage boolean
  status

device_sessions
  device_session_id uuid primary key
  identity_id uuid nullable
  actor_type account | extension
  actor_reference uuid
  device_id_hash text
  token_version integer
  created_at timestamptz
  last_seen_at timestamptz
  expires_at timestamptz
  revoked_at timestamptz nullable

extension_notification_recipients
  recipient_id uuid primary key
  fusion_domain_uuid uuid
  extension_uuid uuid
  channel email
  address canonical-email
  event_type
  enabled boolean
```

Required integrity rules include:

- Identity primary email is globally unique after canonicalization;
- a provider subject maps to only one Identity;
- every assignment's Extension belongs to its declared Domain;
- every assignment belongs to the Customer mapped to that PBX tenant;
- an active Customer has at least one owner before self-service is enabled;
- shared-Domain assignments cannot be authorized through Domain scope alone;
- notification recipients do not create or imply Identity records.

## 7. API Boundaries

Phase 1–2 should expose versioned, narrowly scoped contracts rather than direct
mobile access to FusionPBX tables.

Minimum account/session APIs:

- login with password;
- begin/complete Google login;
- refresh session;
- logout current device;
- logout all devices;
- list/revoke device sessions;
- retrieve current Identity and active Customer context.

Minimum customer APIs:

- list the Identity's Customer memberships;
- retrieve current Customer summary;
- list Extensions assigned for use;
- list Extensions manageable by the current role;
- select or provision an Extension;
- list/update permitted Extension self-service settings.

Minimum legacy APIs:

- resolve and authenticate an Extension inside an explicit tenant context;
- register/revoke an Extension device session;
- list/update only that Extension's permitted settings.

Every API must derive actor, Customer, Domain, and Extension scope from a
verified session. Client-supplied IDs are lookup targets, not proof of ownership.

## 8. Google and Password Identity Rules

- Google login is linked by stable provider subject, not by display name.
- Email must be verified before it becomes the primary account email.
- An existing password Identity and a new Google login with the same email must
  use an explicit authenticated linking flow; automatic linking is prohibited.
- Password reset affects only the application/customer credential and must not
  rotate SIP credentials.
- Removing Google must not lock out the Identity if it is the last provider;
  require adding another provider or password first.
- Changing primary email requires verification and audit logging.
- Customer ownership transfer and provider unlinking are high-risk operations
  and require recent authentication.

## 9. Mphone Application State

The target local model is:

```text
AppProfile
  mode managed_account | multi_sip

ManagedAccountSession
  identity_id
  customer_id
  device_session_id
  secure access/refresh credential references

SipAccount
  local_account_id
  origin managed_account | mphone_extension | third_party
  fusion_domain_uuid nullable
  extension_uuid nullable
  display_label
```

Managed Account Extensions are server-controlled projections. If an assignment
is disabled or removed, the corresponding SIP registration must be disabled on
the next bounded session check. Manually entered Multi-SIP accounts are
device-controlled.

Tokens and reusable secrets must use Android Keystore-backed encrypted storage.
Plain JSON preferences may contain non-sensitive identifiers and display state,
not bearer or SIP credentials.

## 10. Work Plan

### Phase 1 — Stabilize identity, actor, and session behavior

#### 1.1 Inventory and contract freeze

- document all current Portal, FusionPBX, Supabase, push, forwarding, logout, and
  Mphone login flows;
- inventory token claims, token storage, credential storage, and every endpoint
  accepting the current token;
- document how existing users and Extensions are assigned and how duplicate
  Extension numbers are handled;
- define API v1 compatibility behavior and rollback flags.

Deliverable: reviewed current-state and target API/session contract.

#### 1.2 Actor model

- introduce explicit `account`, `extension`, and device-local `third_party`
  origins;
- make Managed Account and Multi-SIP mutually exclusive application modes;
- preserve suspended Multi-SIP configuration during mode switches;
- display origin labels for third-party SIP accounts.

Deliverable: actor/mode state machine with migration tests.

#### 1.3 Tenant-aware login

- bind common login to the shared Domain;
- bind VIP login hosts/slugs to their dedicated Domains;
- stop global username or Extension lookup without tenant context;
- define non-enumerating error responses for unknown tenant, user, or Extension.

Deliverable: tenant-aware password and Extension login endpoints.

#### 1.4 Session hardening

- add server-side Device Sessions;
- issue short access tokens and rotating refresh tokens;
- add revocation, logout-all-devices, reuse detection, and rate limits;
- version JWT claims and enforce issuer, audience, actor type, tenant, and scope;
- recheck enabled state and assignment at defined security boundaries.

Deliverable: session lifecycle tests covering disable, revoke, rotation, replay,
and expiry.

#### 1.5 Scope hardening

- audit every Portal/Supabase endpoint for Domain-only assumptions;
- prohibit shared-Domain customer actors from Domain-wide permissions;
- enforce assigned-Extension scope for account actors and self scope for
  Extension actors;
- add cross-Customer negative tests.

Deliverable: authorization matrix and automated isolation tests.

#### 1.6 Credential containment

- stop logging sensitive login and device material;
- move mobile session secrets into protected storage;
- specify provisioning-envelope/device-SIP credential migration;
- retain the current SIP password flow only behind an explicit compatibility
  flag until the replacement has been tested.

Deliverable: threat review and approved credential migration contract.

### Phase 2 — Introduce the Customer Platform core

#### 2.1 Schema and ownership

- create the minimum Identity, provider, Customer, Membership, PBX Tenant,
  Extension Assignment, Device Session, and notification-recipient schema;
- define unique constraints, lifecycle states, audit columns, and deletion policy;
- keep future billing identifiers independent from FusionPBX identifiers.

Deliverable: reviewed migrations and data dictionary.

#### 2.2 Existing-data migration

- create Customers for the current shared-Domain population using an approved
  grouping source;
- create one initial owner per Customer;
- map VIP Customers to dedicated Domains;
- import Identity-to-Extension relationships from `v_extension_users` only after
  Customer ownership is known;
- produce exception reports for missing email, duplicate email, orphaned users,
  unassigned Extensions, and ambiguous Customer ownership;
- make migration repeatable and idempotent.

Deliverable: dry-run report, reconciliation report, and rollback procedure.

#### 2.3 Identity provider integration

- implement password identities without reusing SIP passwords;
- integrate Google login and explicit provider linking;
- implement email verification, password recovery, recent-auth checks, and
  account disablement;
- decide whether FusionPBX PHP sessions are created by a bridge or by a controlled
  login handoff.

Deliverable: end-to-end account login for Portal and Mphone pilot users.

#### 2.4 Customer and Extension APIs

- expose current Identity, Membership, Customer, assigned Extensions, manageable
  Extensions, and devices;
- add narrow Extension self-service operations;
- keep FusionPBX as source of truth for telephony configuration;
- reconcile Customer Platform assignments with FusionPBX assignments and alert
  on drift.

Deliverable: versioned APIs with contract and authorization tests.

#### 2.5 Portal integration

- add Customer context to the existing server-side Portal session;
- retain FusionPBX permission checks;
- apply Customer/assignment scope before every shared-Domain query;
- expose only the account features approved for Phase 2.

Deliverable: Portal pilot with Customer A/B isolation tests.

#### 2.6 Mphone Managed Account integration

- authenticate one active Managed Account per installation;
- fetch all `can_use` Extensions and maintain their managed registrations;
- respond safely to assignment removal, session revocation, or Customer disable;
- preserve Extension and third-party SIP Multi-SIP mode;
- keep legacy Extension login behind a feature flag.

Deliverable: pilot APK and server rollout with reversible feature flags.

## 11. Migration and Rollout Strategy

1. Add new schema and endpoints without changing existing clients.
2. Issue versioned tokens to internal test accounts.
3. Migrate one test Customer inside the shared Domain.
4. Prove Customer A/B isolation with positive and negative tests.
5. Pilot one VIP Domain to prove tenant-specific login routing.
6. Enable Managed Account mode for a small allowlist.
7. Monitor login failure, refresh failure, assignment drift, session revoke delay,
   provisioning failure, and push registration metrics.
8. Expand gradually while retaining legacy Extension login and rollback flags.
9. Remove compatibility paths only after usage, recovery, and support evidence is
   reviewed.

No migration step may silently delete local Mphone SIP configuration or change
SIP credentials for desk phones and other registered devices.

## 12. Test Matrix

At minimum, automated and targeted integration tests must cover:

- password login, Google login, provider linking, email verification, and reset;
- one account with one and multiple assigned Extensions;
- one Identity in multiple Customers;
- Customer owner management versus Extension use permission;
- two Customers in the shared Domain with overlapping feature permissions;
- VIP Domain login and duplicate Extension numbers across Domains;
- multiple Mphone Extensions mixed with multiple third-party SIP accounts;
- rejection of adding manual SIP accounts while Managed Account mode is active;
- safe mode switching without credential or configuration loss;
- disabled Identity, Membership, Customer, Domain, User, and Extension;
- assignment removal while a device is online;
- access expiry, refresh rotation, token replay, device revoke, and logout all;
- no Customer or Portal access for Extension actors;
- no server/customer access for third-party SIP accounts;
- duplicate notification emails across Extensions without login implications;
- secrets and personal data absent from application and server logs.

## 13. Phase Exit Criteria

### Phase 1 exit

- all three Mphone modes have an approved state machine;
- tenant-aware login is enforced;
- actor/scopes and token version are documented and tested;
- Device Sessions support refresh rotation and revocation;
- shared-Domain endpoints have cross-Customer isolation tests;
- credential migration and legacy rollback behavior are approved;
- no required workflow depends on globally unique Extension numbers.

### Phase 2 exit

- every active pilot account maps to an Identity and Customer;
- every Customer has an owner and PBX Tenant mapping;
- all exposed Extensions have explicit use/manage assignments;
- Portal and Mphone use the same Customer identity/session model;
- ordinary shared-Domain customers cannot obtain Domain-wide data;
- VIP and shared tenants both work with the common platform;
- migration and reconciliation are repeatable and auditable;
- future Subscription and Billing records can reference `customer_id` without
  schema changes to FusionPBX users or Domains.

## 14. Decisions Required Before Implementation

The following decisions materially affect API or migration design and must be
approved before their dependent work begins:

1. Which service owns Customer Platform data: the existing self-hosted Supabase
   database or a separate application database?
2. Is the unique account email case-insensitive only, and what exact
   canonicalization policy is allowed beyond trimming and lowercasing?
3. What source determines Customer grouping for existing users in the shared
   Domain?
4. Who becomes the initial owner when a Customer is migrated?
5. May an Extension be usable by multiple Identities, and may one Identity use
   Extensions from multiple Customers simultaneously?
6. Which Portal features are included in the first Managed Account release?
7. What are the access-token lifetime, refresh-token lifetime, offline grace
   period, and maximum revoke delay?
8. What temporary compatibility period is allowed for SIP-password Extension
   login and SIP password delivery?
9. Will VIP login use a dedicated hostname, tenant slug, `extension@domain`, or a
   combination?
10. Is a Customer allowed to map to multiple FusionPBX Domains in Phase 2, or is
    support schema-only until a later phase?

These decisions should be recorded as short architecture decision records before
implementation so that authentication, Portal, Mphone, and billing do not adopt
different assumptions.
