# Mphone Identity and Account Plan — Preliminary

Status: proposal for a separate discovery track; no authentication, Supabase, FusionPBX, or Android behavior is changed by this document.

Date: 2026-08-21

## 1. Fixed Product Boundaries

- Mphone continues to support direct login with third-party SIP accounts.
- The current Extension-via-Supabase login remains available until a replacement or migration is explicitly approved.
- The first product scope remains PBX usage; do not introduce Softphone.Pro-style Team, invitation, subscription, or special personal-account features.
- Portal, PBX authorization, SIP registration, and application identity are related but must not be treated as the same credential automatically.

## 2. Identities That Must Be Separated

1. **Customer/tenant**: the organization owning a FusionPBX Domain.
2. **Application user**: a person who may manage or use one or more Extensions.
3. **Extension**: a PBX endpoint with calling permissions and SIP provisioning.
4. **Third-party SIP account**: an account outside the managed FusionPBX tenant.
5. **Device installation**: a revocable Mphone instance used for push and session health.

Supabase should broker sessions and delivery, not become an independent source of truth for PBX ownership.

## 3. Candidate Models

### Model A — Customer account with assigned Extensions

One application user authenticates once, then selects from Extensions assigned by the tenant administrator.

Advantages: good recovery and revocation, supports several Extensions without sharing SIP passwords, and aligns with Portal permissions.

Cost: requires an authoritative user-to-Extension assignment and a safe provisioning contract.

### Model B — Separate login for each Extension

Each Extension authenticates independently, close to the current numeric Extension flow.

Advantages: simple mental model and compatible with current deployments.

Cost: weak person-level audit/recovery, awkward multi-Extension usage, and greater exposure of SIP credentials.

### Model C — Hybrid

Support both managed customer-account login and direct Extension login, while third-party SIP remains a separate explicit mode.

Advantages: safest migration path and works for both small and managed customers.

Cost: more UI states, token scopes, recovery rules, and support documentation.

Preliminary recommendation: evaluate Model C as the migration model, with Model A as the preferred managed-customer experience. Do not remove Model B until adoption, recovery, and compatibility evidence supports it.

## 4. Decisions Required

- Is the primary customer credential a FusionPBX user, email/phone identity, or a separately verified account?
- Who creates the first tenant administrator and how is tenant ownership verified?
- Can one user belong to multiple Domains, and can one Extension be assigned to multiple users?
- Is Extension login authenticated with the SIP password or a separate application credential?
- How are password reset, lost-device recovery, logout-all-devices, and staff departure handled?
- How is SIP provisioning delivered without exposing reusable passwords more broadly than required?
- What can each actor type read or change in Portal, Supabase functions, and Mphone?
- How are duplicate Extension numbers disambiguated across Domains?

## 5. Security Contract to Design

- JWT claims must include issuer, audience, actor type, tenant/domain, subject, expiry, and narrow scopes.
- Every Extension operation must recheck Domain ownership or explicit assignment server-side.
- Device sessions need rotation, revocation, bounded lifetime, and an audit trail.
- Do not log SIP passwords, Supabase secrets, JWTs, or FCM tokens.
- Prefer short-lived provisioning envelopes or device-bound secrets over returning a long-lived SIP password repeatedly.
- Rate-limit login, recovery, provisioning, and device-registration endpoints.
- Define behavior for disabled users, disabled Extensions, Domain moves, and credential rotation.

## 6. Proposed Discovery Sequence

### Step 1 — Inventory current behavior

Document all Android login modes, local credential storage, Edge Functions, JWT actor types/scopes, Fusion assignments, push registration, logout, and recovery paths.

### Step 2 — Define customer scenarios

At minimum cover: one person/one Extension, one person/multiple Extensions, company admin assigning staff, shared Extension, multiple Domains, and third-party SIP-only usage.

### Step 3 — Decision matrix and threat review

Score Models A–C for usability, migration, support load, credential exposure, revocation, auditability, offline behavior, and compatibility.

### Step 4 — Approve contracts

Specify login, refresh, provisioning, Extension selection, device registration, logout, revocation, and recovery APIs before changing UI or schema.

### Step 5 — Migration and compatibility plan

Define feature flags, actor-version claims, old-session expiry, rollback, telemetry, and customer communication. Preserve third-party SIP accounts throughout.

### Step 6 — Controlled implementation

Implement server-side contracts first, then Android selection/login UI, then Portal account/Extension assignment controls. Pilot one Domain before broad rollout.

## 7. Exit Criteria for the Separate Plan

- Product owner approves one target model and migration policy.
- Authentication and recovery have a documented threat review.
- User/Domain/Extension ownership rules are unambiguous.
- API and JWT contracts are versioned and testable.
- Third-party SIP compatibility is verified.
- Rollback and old-session handling are defined before deployment.
