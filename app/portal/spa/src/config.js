// ==============================|| THEME CONSTANT ||============================== //

export const APP_DEFAULT_PATH = '/dashboard';
export const DRAWER_WIDTH = 260;
export const MINI_DRAWER_WIDTH = 60;

// the portal is mounted under /p/ by nginx and the FusionPBX menu links here.
// Vite reads the same value from .env so asset URLs and routes cannot drift apart.
export const BASE_PATH = import.meta.env.VITE_APP_BASE_NAME || '/p';

// server rendered endpoints the portal talks to
export const SESSION_URL = '/app/portal/service/session.php';
export const IDENTITY_URL = '/app/portal/service/identity.php';
export const IDENTITY_LIFECYCLE_URL = '/app/portal/service/identity_lifecycle.php';
export const USERS_URL = '/app/portal/service/users.php';
export const CUSTOMERS_URL = '/app/portal/service/customers.php';
export const DID_INVENTORY_URL = '/app/portal/service/did_inventory.php';
export const SIMPLE_CALL_ROUTING_URL = '/app/portal/service/simple_call_routing.php';
export const GREETING_RECORDING_URL = '/app/portal/service/greeting_recording.php';
export const GOOGLE_OAUTH_URL = '/app/portal/service/google_oauth.php';
export const ACCOUNT_URL = '/app/portal/service/account.php';
export const WORKSPACES_URL = '/app/portal/service/workspaces.php';
export const BILLING_URL = '/app/portal/service/billing.php';
export const CUSTOMER_URL = '/app/portal/service/customer.php';
export const DASHBOARD_URL = '/app/portal/service/dashboard.php';
export const CALLS_URL = '/app/portal/service/calls.php';
export const RECORDING_URL = '/app/portal/service/recording.php';
export const CALL_ENRICHMENT_URL = '/app/portal/service/call_enrichment.php';
export const SUMMARY_RETRY_URL = '/app/portal/service/summary_retry.php';
export const CALL_TAGS_URL = '/app/portal/service/call_tags.php';
export const CALL_NOTES_URL = '/app/portal/service/call_notes.php';
export const RECORDINGS_URL = '/app/portal/service/recordings.php';
export const REPORTS_URL = '/app/portal/service/reports.php';
export const MISSED_CALLS_URL = '/app/portal/service/missed_calls.php';
export const CONTACTS_URL = '/app/portal/service/contacts.php';
export const SETTINGS_URL = '/app/portal/service/settings.php';
export const FORWARDING_URL = '/app/portal/service/forwarding.php';
export const CLICK_TO_CALL_URL = '/app/portal/service/click_to_call.php';
export const LOGIN_URL = '/';
export const LOGOUT_URL = '/logout.php';
export const ADMIN_URL = 'https://pbx.mphone.vn/core/dashboard/';

const config = {
  fontFamily: `'Public Sans', sans-serif`
};

export default config;
