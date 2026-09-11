# Mphone Account Center Plan

Status: proposal for implementation planning
Primary language: English
Vietnamese companion: `MPHONE_ACCOUNT_CENTER_PLAN_VI.md`

## 1. Objective

Build a shared account area for the Mphone ecosystem around two independent
subjects:

- **Identity** is the human who authenticates and performs an action.
- **Customer** is the individual or organization that consumes, owns, and pays
  for services.

The existing Customer Platform will be the authoritative source for identity,
authentication context, sessions, Memberships, and Customer authorization for
the Portal, Mphone applications, and future customer-facing services.

FusionPBX users, Google accounts, and Odoo contacts must not become the central
user identifier.

## 2. Domain model

```text
Google / Password / Future providers
                  |
                  | authenticate
                  v
               Identity
                  +-- Personal profile
                  +-- Authentication providers
                  +-- Device sessions
                  |
                  +-- Membership
                          |
                          v
                       Customer
                          +-- Members and roles
                          +-- Extensions and services
                          +-- Plans and billing
                          +-- Customer profile
```

One Identity may belong to multiple Customers. One Customer may contain
multiple Identities with the roles `owner`, `customer_admin`, `billing_admin`,
or `member`.

A Customer is not permanently owned by one person. Ownership is represented by
a Membership with the `owner` role and can change through a dedicated, audited
workflow.

## 3. Identity and authentication

The Customer Platform is the authoritative Identity source. Google is an
authentication provider, not the user database.

```text
mphone_identities
    identity_uuid
    primary_email
    status
         +-- mphone_identity_providers
                +-- password
                +-- google
                +-- future providers
```

Every sign-in method must resolve to the same `identity_uuid`. Provider linking
must not rely only on a matching email address. It requires an authenticated
session plus recent authentication, or a controlled recovery flow.

FusionPBX users remain compatibility principals during migration; they are not
the ecosystem-wide Identity source.

## 4. Account Center structure

The first implementation should extend the current Portal rather than create a
separate frontend application.

```text
/p/account                 My Account
/p/customers               My Workspaces
/p/customer/profile        Workspace Information
/p/customer/members        Members and authorization
/p/customer/services       Extensions and services
/p/customer/billing        Plans, invoices, and payments
/p/customer/security       Audit and privileged sessions
```

### 4.1 My Account — `/p/account`

The subject is the authenticated Identity. It includes name, avatar, personal
telephone, verified email, password, linked providers, locale, time zone, device
sessions, and the Identity's Customer Memberships.

Personal application profile data should use a new one-to-one Customer Platform
table:

```text
mphone_identity_profiles
    identity_uuid
    full_name
    phone_number
    avatar_object_key
    locale
    timezone
    created_at
    updated_at
    version
```

Email and provider data remain in `mphone_identities` and
`mphone_identity_providers`. Avatar files belong in object storage; the database
stores only an object key and metadata.

### 4.2 My Workspaces — `/p/customers`

Show all active Memberships for the authenticated Identity and allow the user to
select an active Customer workspace.

```text
Nguyen Van A
  +-- ABC Company -- owner
  +-- XYZ Company -- member
  +-- Personal Workspace -- owner
```

The server must validate the selected Membership and issue a refreshed session
or token context. React must never establish authorization by changing
`customer_uuid` locally.

### 4.3 Workspace Information — `/p/customer/profile`

The subject is the active Customer. Owners and, subject to final policy,
customer administrators may edit ordinary contact information:

- Display name.
- Contact person, telephone, and email.
- Contact address.

The Portal must not directly modify Customer code, status, type, tax identifier,
legal name, billing address, PBX tenant, subscription, price, or service status.
Legal and billing changes create a verification request for Odoo or an operator.

### 4.4 Members — `/p/customer/members`

Capabilities include listing and inviting members, assigning supported roles,
suspending or removing Memberships, assigning Customer-owned Extensions, and
managing `can_use` and `can_manage`.

The final active owner cannot be removed or demoted. Ownership transfer must use
a dedicated operation rather than a generic role update. The server must scope
every target Membership and Extension to the active Customer.

### 4.5 Services — `/p/customer/services`

Customers may view their Extensions, Identity assignments, effective
permissions, and related customer-facing services. Only narrow, explicitly
authorized self-service writes belong here.

FusionPBX administration remains outside the Account Center. Customers cannot
manage Domains, dialplans, shared SIP profiles, system configuration, or
Extension ownership transfers between Customers.

### 4.6 Billing — `/p/customer/billing`

Customers may view plans, billing cycles, invoices, outstanding amounts,
balances, and payment history, and make payments when supported.

Odoo is authoritative for legal Customer data, contracts, commercial plans,
invoices, and receivables. The Customer Platform may retain a reliable read
projection for Portal and Mphone.

### 4.7 Security — `/p/customer/security`

Expose role-appropriate history for Membership changes, Customer profile
updates, ownership transfers, privileged actions, affected sessions, and
security notifications.

Each event must retain both actor and workspace context:

```text
actor_identity_uuid
customer_uuid
membership_uuid
action
target_type
target_id
occurred_at
```

## 5. Customer context and token contract

The shared session or access-token context should include at least:

```text
identity_uuid
active_customer_uuid
membership_uuid
membership_role
tenant_uuid
session_uuid
authorization_version
expires_at
```

`identity_uuid` identifies the human actor; `active_customer_uuid` identifies
the business workspace; `membership_uuid` proves the relationship used for
access; `tenant_uuid` binds telephony resources to the PBX context;
`session_uuid` enables revocation; and `authorization_version` invalidates stale
authorization after a role or capability change.

Every endpoint must independently validate Identity, Customer, Membership,
tenant, status, and required capability. Browser-side visibility is not
authorization.

## 6. System ownership boundaries

| System | Authoritative responsibilities |
|---|---|
| Customer Platform | Identity, personal profile, Membership, Customer context, sessions, authorization |
| Google | External authentication provider |
| Odoo | CRM, legal profile, contracts, commercial plans, invoices, receivables |
| FusionPBX | Domains, Extensions, SIP, telephony devices, call data |
| Portal and Mphone | User experiences consuming the platform APIs |

Every field must have one authoritative owner. Uncontrolled bidirectional
synchronization is not permitted.

## 7. Odoo synchronization

An Odoo-linked Customer should use an asynchronous integration flow:

```text
Portal -> Customer Platform -> idempotent outbox -> Odoo
                                              -> Customer Platform projection
```

Requirements:

- Do not call Odoo during every Account Center page load.
- Support `pending`, `synced`, `failed`, and `verification_required` states.
- Provide idempotency and retry handling.
- Do not report synchronization success before the state is known.
- Record audit data without credentials or tokens.
- Preserve sign-in and unrelated functionality during an Odoo outage.

Portal-owned contact fields may update immediately only when the field ownership
policy assigns them to the Customer Platform. Odoo-owned fields must use the
integration or verification workflow.

## 8. Ownership transfer

An active Customer must retain at least one active owner.

Recommended workflow:

1. The current owner selects an active member.
2. The recipient accepts the transfer request.
3. Recent authentication is required where appropriate.
4. One database transaction promotes the recipient, demotes the former owner to
   the confirmed role, verifies the owner invariant, increments the authorization
   version, invalidates affected privileged sessions, and records the audit event.
5. A controlled superadmin recovery process handles an inaccessible owner.

The generic Membership update operation must not substitute for this workflow.

## 9. Proposed authorization matrix

| Capability | Owner | Customer admin | Billing admin | Member |
|---|---:|---:|---:|---:|
| Edit display/contact profile | Yes | Proposed | No | No |
| Request legal-profile changes | Yes | Proposed | Proposed | No |
| Manage members | Yes | Limited | No | No |
| Transfer ownership | Dedicated flow | No | No | No |
| View billing | Yes | By capability | Yes | No |
| Manage Customer Extension assignments | Yes | By capability | View only | Own only |
| Manage PBX tenant/global configuration | No | No | No | No |

Roles provide defaults, but server-side capabilities govern each operation.

## 10. Delivery phases

### Phase 1 — Identity profile

- Add `mphone_identity_profiles` and its migration.
- Add narrowly scoped profile read/update APIs.
- Upgrade `/p/account` with bilingual forms and validation states.
- Preserve the verified email-change and password flows.
- Add CSRF, normalization, optimistic concurrency, appropriate rate limits, and
  audit events.

### Phase 2 — Customer context

- Add the authorized Membership list API.
- Implement `/p/customers` and the Customer switcher.
- Reissue server-side context on Customer selection.
- Add and enforce `authorization_version`.
- Revalidate context during refresh and privileged operations.

### Phase 3 — Customer profile

- Define Customer contact-profile storage and field ownership.
- Implement `/p/customer/profile`.
- Enforce owner/customer-administrator capabilities.
- Separate immediate changes from verified legal changes.
- Complete Odoo outbox, status, and retry handling.

### Phase 4 — Membership and ownership

- Complete `/p/customer/members`.
- Standardize role-to-capability resolution.
- Complete invitation, suspension, removal, and Extension-assignment flows.
- Add the dedicated ownership-transfer workflow.
- Invalidate sessions when authorization changes.

### Phase 5 — Services, billing, and security

- Implement `/p/customer/services`.
- Complete `/p/customer/billing`.
- Implement `/p/customer/security`.
- Add Customer-visible audit history, alerts, and privileged-action history.

## 11. Invariants

- Identity is the actor; Customer is the workspace.
- The Customer Platform is the authoritative Identity source.
- Google is an authentication provider, not the user owner.
- `customer_uuid` never substitutes for the actor Identity.
- FusionPBX `user_uuid` is not the ecosystem-wide identifier.
- FusionPBX administration and shared configuration stay outside the Portal.
- Server-side scope always constrains Identity, Customer, Membership, tenant,
  and owned resources.
- Email, password, ownership, and legal-profile changes use dedicated security
  workflows.
- Every field has one authoritative system.
- Every privileged write is auditable and invalidates stale authorization when
  necessary.

## 12. Decisions required before technical design

1. May `customer_admin` edit the Customer contact profile, or only an owner?
2. May one Customer have multiple simultaneous owners?
3. Does ownership transfer require recipient acceptance, superadmin approval,
   or both for selected Customer types?
4. Which Customer fields are always authoritative in Odoo?
5. Is a personal Customer created automatically when an Identity registers?
6. Must multiple-Customer Membership and switching ship in the first release?
7. Should the Account Center remain under `/p/`, or later move to a dedicated
   host such as `account.mphone.vn`?
8. Which operations require explicit capabilities instead of role inference?

Resolve these decisions before finalizing API contracts, database migrations,
and delivery estimates.

## 13. User-facing terminology and naming

Technical terms such as Identity, Customer, Membership, and Customer context are
appropriate in architecture, APIs, database schemas, and operator tools. They
should not be exposed directly throughout the customer interface in either
language.

The interface must clearly answer two different questions:

- **Who is signed in?** — `My Account` in English and `Tài khoản của tôi` in
  Vietnamese.
- **Which Customer context is active?** — `Workspace` in English and `Hồ sơ
  dịch vụ` in Vietnamese.

The two locale catalogues intentionally use different natural terms. `Workspace`
is standard, concise English for a switchable Customer context. `Hồ sơ dịch vụ`
is the preferred Vietnamese label because it is more natural than `Không gian`
and less likely than `Tài khoản dịch vụ` to be confused with authentication.
Do not translate either label literally into the other locale.

### 13.1 Approved localized vocabulary

| Technical concept | English UI | Vietnamese UI |
|---|---|---|
| Account Center | Account Center | Trung tâm tài khoản |
| Identity account | My Account | Tài khoản của tôi |
| Personal Identity profile | Personal Information | Thông tin cá nhân |
| Customer | Workspace | Hồ sơ dịch vụ |
| Customer list | My Workspaces | Hồ sơ dịch vụ |
| Active Customer | Current Workspace | Hồ sơ đang sử dụng |
| Customer switcher | Switch Workspace | Chuyển hồ sơ |
| Individual Customer | Personal Workspace | Hồ sơ cá nhân |
| Organization Customer | Organization Workspace | Hồ sơ doanh nghiệp |
| Customer profile | Workspace Information | Thông tin hồ sơ |
| Membership | Workspace Membership | Quyền tham gia |
| Owner | Owner | Chủ sở hữu |
| Customer administrator | Administrator | Quản trị viên |
| Billing administrator | Billing Administrator | Quản trị thanh toán |
| Member | Member | Thành viên |
| Ownership transfer | Transfer Ownership | Chuyển quyền sở hữu |

The word `Khách hàng` remains appropriate in FusionPBX/operator interfaces,
support tools, reports, and internal documentation. Customer UUID and other
technical identifiers must not be relabeled in code or API contracts.

### 13.2 Approved navigation labels

| Route | English label | Vietnamese label |
|---|---|---|
| `/p/account` | My Account | Tài khoản của tôi |
| `/p/customers` | My Workspaces | Hồ sơ dịch vụ |
| `/p/customer/profile` | Workspace Information | Thông tin hồ sơ |
| `/p/customer/members` | Members | Thành viên |
| `/p/customer/services` | Services & Extensions | Dịch vụ & máy nhánh |
| `/p/customer/billing` | Billing | Thanh toán |
| `/p/customer/security` | Security & Activity | Bảo mật & hoạt động |

The personal and Workspace areas should remain visually distinct. In English:

```text
My Account
  +-- Personal Information
  +-- Sign-in & Security
  +-- My Devices

Workspace
  +-- Workspace Information
  +-- Members
  +-- Services & Extensions
  +-- Billing
  +-- Security & Activity
```

The Vietnamese equivalent is:

```text
Tài khoản của tôi
  +-- Thông tin cá nhân
  +-- Đăng nhập & bảo mật
  +-- Thiết bị của tôi

Hồ sơ dịch vụ
  +-- Thông tin hồ sơ
  +-- Thành viên
  +-- Dịch vụ & máy nhánh
  +-- Thanh toán
  +-- Bảo mật & hoạt động
```

### 13.3 Workspace selector

Prefer conversational labels over technical context terminology. In English:

```text
Currently using services for:

ABC Company
Organization · Owner
```

The English selector may list Workspaces as follows:

```text
Switch Workspace

Nguyen Van A
Personal · Owner

ABC Company
Organization · Owner

XYZ Company
Organization · Member
```

The corresponding Vietnamese presentation is:

```text
Bạn đang sử dụng dịch vụ cho:

Công ty ABC
Doanh nghiệp · Chủ sở hữu
```

The selector may list profiles as follows:

```text
Chuyển hồ sơ

Nguyễn Văn A
Cá nhân · Chủ sở hữu

Công ty ABC
Doanh nghiệp · Chủ sở hữu

Công ty XYZ
Doanh nghiệp · Thành viên
```

Approved English actions include `Switch Workspace`, `Manage Workspace`, `Create
Organization`, and `Leave Workspace`. Approved Vietnamese actions include
`Chuyển hồ sơ`, `Quản lý hồ sơ`, `Tạo hồ sơ doanh nghiệp`, and `Rời khỏi hồ sơ`.
Avoid `Select Customer`, `Customer context`, or `Switch Account` in English
customer-facing copy, and avoid `Chọn Customer`, `Customer context`, or `Chuyển
tài khoản` in Vietnamese customer-facing copy.

### 13.4 Naming rules

- Use `My Account` / `Tài khoản của tôi` only for Identity-owned information.
- Use `Workspace` / `Hồ sơ dịch vụ` for the Customer collection or general
  Customer concept.
- Once the type is known, show `Personal` / `Cá nhân` or `Organization` /
  `Doanh nghiệp`.
- Always show the active Workspace name on Customer-scoped pages.
- Mention the affected Workspace name in confirmations for role, billing, and
  ownership changes.
- Keep backend names (`identity_uuid`, `customer_uuid`, `membership_uuid`) and
  API contracts unchanged.
- Store all new labels in both Vietnamese and English locale catalogues; do not
  hardcode them in React components.
