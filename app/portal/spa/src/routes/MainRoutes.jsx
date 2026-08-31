import { lazy } from 'react';
import { Navigate } from 'react-router-dom';

// project imports
import Loadable from 'components/Loadable';
import DashboardLayout from 'layout/Dashboard';
import { APP_DEFAULT_PATH } from 'config';
import useSession from 'hooks/useSession';

const Overview = Loadable(lazy(() => import('pages/dashboard/Overview')));
const ActiveCalls = Loadable(lazy(() => import('pages/calls/ActiveCalls')));
const CallHistory = Loadable(lazy(() => import('pages/calls/CallHistoryPhase1')));
const Recordings = Loadable(lazy(() => import('pages/recordings/Recordings')));
const Reports = Loadable(lazy(() => import('pages/reports/Reports')));
const MissedCalls = Loadable(lazy(() => import('pages/missed/MissedCalls')));
const Contacts = Loadable(lazy(() => import('pages/contacts/Contacts')));
const Settings = Loadable(lazy(() => import('pages/settings/Settings')));
const Account = Loadable(lazy(() => import('pages/account/Account')));
const SystemUsers = Loadable(lazy(() => import('pages/users/SystemUsers')));
const CustomerMembers = Loadable(lazy(() => import('pages/users/CustomerMembers')));
const CustomerArea = Loadable(lazy(() => import('pages/customers/CustomerArea')));
const CustomerProfile = Loadable(lazy(() => import('pages/customers/CustomerProfile')));
const CustomerServices = Loadable(lazy(() => import('pages/customers/CustomerServices')));
const CustomerSecurity = Loadable(lazy(() => import('pages/customers/CustomerSecurity')));
const Billing = Loadable(lazy(() => import('pages/billing/Billing')));
const DidInventory = Loadable(lazy(() => import('pages/dids/DidInventory')));
const SimpleCallRouting = Loadable(lazy(() => import('pages/routing/SimpleCallRouting')));

// ==============================|| MAIN ROUTING ||============================== //

function LandingRedirect() {
  const { session } = useSession();
  return <Navigate to={session?.identity && !session?.workspace?.active ? '/customers' : APP_DEFAULT_PATH} replace />;
}

function LegacyUsersRedirect() {
  const { session } = useSession();
  return <Navigate to={session?.identity ? '/customer/members' : '/admin/users'} replace />;
}

const MainRoutes = {
  path: '/',
  element: <DashboardLayout />,
  children: [
    {
      path: '/',
      element: <LandingRedirect />
    },
    {
      path: 'recordings',
      element: <Recordings />
    },
    {
      path: 'reports',
      element: <Reports />
    },
    {
      path: 'missed-calls',
      element: <MissedCalls />
    },
    {
      path: 'contacts',
      element: <Contacts />
    },
    {
      path: 'settings',
      element: <Settings />
    },
    {
      path: 'account',
      element: <Account />
    },
    {
      path: 'users',
      element: <LegacyUsersRedirect />
    },
    {
      path: 'admin/users',
      element: <SystemUsers />
    },
    {
      path: 'customer/members',
      element: <CustomerMembers />
    },
    {
      path: 'customer/profile',
      element: <CustomerProfile />
    },
    {
      path: 'customer/services',
      element: <CustomerServices />
    },
    {
      path: 'customer/security',
      element: <CustomerSecurity />
    },
    {
      path: 'customers',
      element: <CustomerArea />
    },
    {
      path: 'admin/dids',
      element: <DidInventory />
    },
    {
      path: 'phone-numbers',
      element: <SimpleCallRouting />
    },
    {
      path: 'billing',
      element: <Billing />
    },
    {
      path: 'dashboard',
      element: <Overview />
    },
    {
      path: 'calls',
      children: [
        {
          path: 'active',
          element: <ActiveCalls />
        },
        {
          path: 'history',
          element: <CallHistory />
        }
      ]
    },
    {
      path: '*',
      element: <Navigate to={APP_DEFAULT_PATH} replace />
    }
  ]
};

export default MainRoutes;
