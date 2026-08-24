# Mphone invitation from FusionPBX Users

Status: deployed on 2026-08-25.

## Operator flow

1. Open **Accounts > Users**.
2. In the **Mphone account** column, select **Invite** for an enabled User that
   does not already have an Mphone Identity.
3. Confirm the invitation. Email and Extension assignments are read directly
   from FusionPBX; the Customer is resolved from Extension ownership.
4. The Identity remains `pending` and the Membership remains
   `invited` until the recipient uses the one-time link.
5. The recipient verifies the email and sets a separate Mphone password. This
   activates both the Identity and invited Memberships.

The FusionPBX user password and SIP password are never copied or synchronized.
The invitation API is server-to-server, requires the existing Customer Identity
edit permission and service credential, validates the Fusion user against the
Customer tenant, and only assigns Extensions already owned by that Customer.

## Upgrade boundary

All invitation logic lives in `app/customer_identities` and the Mphone Edge
Functions. The FusionPBX Users list has one guarded status/action column. A
FusionPBX upgrade may overwrite that small integration, while the invitation
endpoint remains independent.

After an upgrade, run:

```sh
php app/customer_identities/resources/tests/self_test.php
```

and verify that the **Mphone account** column is still present on the Users list.
